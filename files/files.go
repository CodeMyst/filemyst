package files

import (
	"os"
	"path/filepath"
	"strings"
	"time"
)

type FileEntry struct {
	Name         string
	Size         uint64
	LastModified time.Time
	IsDir        bool
}

func GetFileSize(path string) (int64, error) {
	var size int64
	err := filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() {
			size += info.Size()
		}

		return err
	})

	return size, err
}

func GetFilesPath() string {
	filesPath := os.Getenv("FILES_PATH")
	if strings.HasPrefix(filesPath, "~/") {
		dirname, _ := os.UserHomeDir()
		filesPath = filepath.Join(dirname, filesPath[2:])
	}

	return filesPath
}
