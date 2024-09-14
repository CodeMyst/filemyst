package main

import (
	"context"
	"database/sql"
	"filemyst/files"
	"filemyst/views"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/gorilla/sessions"
	"github.com/joho/godotenv"
	"github.com/labstack/echo-contrib/session"
	"github.com/labstack/gommon/log"
	_ "github.com/mattn/go-sqlite3"
	"golang.org/x/crypto/bcrypt"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

var db *sql.DB

func setupUserModel() error {
	createUserSql := `
		create table if not exists users (
			id integer primary key autoincrement,
			username text not null,
			password text not null
		);
	`

	_, err := db.Exec(createUserSql)
	return err
}

func setupAdminUser() error {
	tx, err := db.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare("insert into users (username, password) values (?, ?)")
	if err != nil {
		return err
	}
	defer stmt.Close()

	username := os.Getenv("ADMIN_USERNAME")
	password := os.Getenv("ADMIN_PASSWORD")

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	_, err = stmt.Exec(username, string(hashedPassword))
	if err != nil {
		return err
	}

	err = tx.Commit()
	return err
}

func handleIndex(c echo.Context) error {
	path := c.Param("*")

	sess, err := session.Get("filemyst-session", c)
	if err != nil {
		return err
	}

	loggedIn, _ := sess.Values["loggedIn"].(bool)

	if !loggedIn && strings.HasPrefix(path, ".trash") {
		return c.NoContent(http.StatusNotFound)
	}

	filesPath := filepath.Join(files.GetFilesPath(), path)

	if _, err := os.Stat(filesPath); os.IsNotExist(err) {
		return c.NoContent(http.StatusNotFound)
	}

	fileInfo, err := os.Stat(filesPath)
	if err != nil {
		return err
	}

	if !fileInfo.IsDir() {
		return c.File(filesPath)
	} else {
		// if the path is a directory, redirect to the directory with a trailing slash
		if !strings.HasSuffix(c.Request().URL.String(), "/") {
			return c.Redirect(http.StatusMovedPermanently, c.Request().URL.String()+"/")
		}
	}

	filesDir, err := os.ReadDir(filesPath)
	if err != nil {
		return err
	}

	var fileEntries []files.FileEntry
	for _, file := range filesDir {
		fileInfo, err := file.Info()
		if err != nil {
			return err
		}

		fileSize, err := files.GetFileSize(filepath.Join(filesPath, fileInfo.Name()))
		if err != nil {
			return err
		}

		fileEntry := files.FileEntry{
			Name:         fileInfo.Name(),
			Size:         uint64(fileSize),
			LastModified: fileInfo.ModTime(),
			IsDir:        fileInfo.IsDir(),
		}

		// if not logged in, don't show hidden files
		if !loggedIn && strings.HasPrefix(fileEntry.Name, ".") {
			continue
		}

		fileEntries = append(fileEntries, fileEntry)
	}

	// sort by whether it's a directory or not, then by size
	sort.Slice(fileEntries, func(i, j int) bool {
		if fileEntries[j].Name == ".trash" {
			return false
		}

		if fileEntries[i].IsDir && !fileEntries[j].IsDir {
			return true
		} else if !fileEntries[i].IsDir && fileEntries[j].IsDir {
			return false
		} else {
			return fileEntries[i].Size > fileEntries[j].Size
		}
	})

	return views.Index(loggedIn, path, fileEntries).Render(context.Background(), c.Response().Writer)
}

func handleLogin(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")

	rows, err := db.Query("select password from users where username = ?", username)
	if err != nil {
		return err
	}
	defer rows.Close()

	var hashedPassword string
	if rows.Next() {
		err = rows.Scan(&hashedPassword)
		if err != nil {
			return err
		}
	}

	err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
	if err != nil {
		return views.LoginModal(true).Render(context.Background(), c.Response().Writer)
	}

	c.Response().Header().Set("HX-Redirect", "/")

	sess, err := session.Get("filemyst-session", c)
	if err != nil {
		return err
	}

	sess.Options = &sessions.Options{
		Path:     "/",
		MaxAge:   86400 * 7,
		HttpOnly: true,
		SameSite: http.SameSiteStrictMode,
		Secure:   os.Getenv("HTTPS") == "true",
	}

	sess.Values["loggedIn"] = true

	if err := sess.Save(c.Request(), c.Response()); err != nil {
		return err
	}

	return c.NoContent(http.StatusOK)
}

func handleLogout(c echo.Context) error {
	sess, err := session.Get("filemyst-session", c)
	if err != nil {
		return err
	}

	sess.Values["loggedIn"] = false

	if err := sess.Save(c.Request(), c.Response()); err != nil {
		return err
	}

	c.Response().Header().Set("HX-Redirect", "/")

	return c.NoContent(http.StatusOK)
}

func handleUpload(c echo.Context) error {
	path := c.Param("*")

	sess, err := session.Get("filemyst-session", c)
	if err != nil {
		return err
	}

	loggedIn, _ := sess.Values["loggedIn"].(bool)
	if !loggedIn {
		return c.NoContent(http.StatusUnauthorized)
	}

	filesPath := filepath.Join(files.GetFilesPath(), path)

	form, err := c.MultipartForm()
	if err != nil {
		return err
	}
	files := form.File["files"]

	for _, file := range files {
		src, err := file.Open()
		if err != nil {
			return err
		}
		defer src.Close()

		// check if destination exists, if so, append a number to the filename
		_, err = os.Stat(filepath.Join(filesPath, file.Filename))
		if err == nil {
			var i int64 = 1
			for {
				filenameWithoutExt := file.Filename[:len(file.Filename)-len(filepath.Ext(file.Filename))]
				ext := filepath.Ext(file.Filename)

				newFilename := filenameWithoutExt + "-" + strconv.FormatInt(i, 10) + ext

				_, err = os.Stat(filepath.Join(filesPath, newFilename))
				if err != nil {
					file.Filename = newFilename
					break
				}
				i++
			}
		}

		dst, err := os.Create(filepath.Join(filesPath, file.Filename))
		if err != nil {
			return err
		}
		defer dst.Close()

		_, err = io.Copy(dst, src)
		if err != nil {
			return err
		}
	}

	return c.NoContent(http.StatusOK)
}

func handleDelete(c echo.Context) error {
	path := c.Param("*")

	sess, err := session.Get("filemyst-session", c)
	if err != nil {
		return err
	}

	loggedIn, _ := sess.Values["loggedIn"].(bool)
	if !loggedIn {
		return c.NoContent(http.StatusUnauthorized)
	}

	filesPath := filepath.Join(files.GetFilesPath(), path)

	if strings.HasPrefix(path, ".trash") {
		err = os.RemoveAll(filesPath)
		if err != nil {
			return err
		}
	} else {
		trashPath := filepath.Join(files.GetFilesPath(), ".trash")

		err = os.Rename(filesPath, filepath.Join(trashPath, filepath.Base(filesPath)))
		if err != nil {
			return err
		}
	}

	c.Response().Header().Set("HX-Refresh", "true")

	return c.NoContent(http.StatusOK)
}

func handleRename(c echo.Context) error {
	path := c.Param("*")

	sess, err := session.Get("filemyst-session", c)
	if err != nil {
		return err
	}

	loggedIn, _ := sess.Values["loggedIn"].(bool)
	if !loggedIn {
		return c.NoContent(http.StatusUnauthorized)
	}

	filesPath := filepath.Join(files.GetFilesPath(), path)

	newName := c.Request().Header.Get("HX-Prompt")

	// check if destination exists, if so, append a number to the filename
	_, err = os.Stat(filepath.Join(filepath.Dir(filesPath), newName))
	if err == nil {
		var i int64 = 1
		for {
			filenameWithoutExt := newName[:len(newName)-len(filepath.Ext(newName))]
			ext := filepath.Ext(newName)

			newFilename := filenameWithoutExt + "-" + strconv.FormatInt(i, 10) + ext

			_, err = os.Stat(filepath.Join(filesPath, newFilename))
			if err != nil {
				newName = newFilename
				break
			}
			i++
		}
	}

	err = os.Rename(filesPath, filepath.Join(filepath.Dir(filesPath), newName))
	if err != nil {
		return err
	}

	c.Response().Header().Set("HX-Refresh", "true")

	return c.NoContent(http.StatusOK)
}

func main() {
	godotenv.Load()

	os.Create("./db/filemyst.db")

	var err error
	db, err = sql.Open("sqlite3", "./db/filemyst.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	err = setupUserModel()
	if err != nil {
		panic(err)
	}

	err = setupAdminUser()
	if err != nil {
		panic(err)
	}

	filesPath := files.GetFilesPath()
	if _, err := os.Stat(filesPath); os.IsNotExist(err) {
		err = os.Mkdir(filesPath, 0755)
		if err != nil {
			panic(err)
		}
	}

	trashPath := filepath.Join(filesPath, ".trash")
	if _, err := os.Stat(trashPath); os.IsNotExist(err) {
		err = os.Mkdir(trashPath, 0755)
		if err != nil {
			panic(err)
		}
	}

	e := echo.New()
	e.Logger.SetLevel(log.INFO)
	e.Use(session.Middleware(sessions.NewCookieStore([]byte("secret"))))
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	e.Static("/assets", "assets")

	e.GET("/*", handleIndex)
	e.POST("/*", handleUpload)
	e.DELETE("/*", handleDelete)
	e.PATCH("/*", handleRename)
	e.POST("/login", handleLogin)
	e.POST("/logout", handleLogout)

	e.Logger.Fatal(e.Start(":8080"))
}
