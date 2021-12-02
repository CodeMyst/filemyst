import vibe.d;
import vibe.web.auth;
import std.array;
import std.stdio;
import std.file;
import std.path;
import std.string;
import std.uri;
import std.typecons;

import filetree;
import auth_info;

// TODO: make sure slash at the end
const string filesPath = "/home/codemyst/Downloads/";

void main()
{
    auto router = new URLRouter();

    auto fsettings = new HTTPFileServerSettings();
    fsettings.serverPathPrefix = "/static";

    router.get("/static/*", serveStaticFiles("static/", fsettings));
    router.registerWebInterface(new IndexWeb());

    auto serverSettings = new HTTPServerSettings();
	serverSettings.bindAddresses = ["127.0.0.1"];
	serverSettings.port = 5000;
    serverSettings.sessionStore = new MemorySessionStore();

    listenHTTP(serverSettings, router);

	runApplication();
}

FileTree getTree(string path)
{
    FileTree root = new FileTree();
    root.name = baseName(path);
    root.isDir = true;
    root.path = path;

    string fpath = chainPath(filesPath, path[1..$]).array().decodeComponent();

    if (!isDir(fpath))
    {
        root.isDir = false;
        return root;
    }

    foreach (DirEntry entry; dirEntries(fpath, SpanMode.shallow))
    {
        FileTree f = new FileTree();
        f.name = entry.name.baseName();
        f.isDir = entry.isDir();
        f.rawsize = entry.size();
        f.prettysize = byteToHumanReadable(f.rawsize, 2);
        f.lastModified = entry.timeLastModified;
        f.path = entry.name().chompPrefix(filesPath);

        root.add(f);
    }

    root.sort();

    return root;
}

@requiresAuth
class IndexWeb
{
    @safe
    @noRoute
    AuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse)
    {
        if (!req.session || !req.session.isKeySet("auth"))
        {
            throw new HTTPStatusException(HTTPStatus.forbidden, "Not authorized to perform this action.");
        }

        return req.session.get!AuthInfo("auth");
    }

    @noAuth
    @path("/login")
    public void getLogin(string _error = null)
    {
        string error = _error;
        Nullable!AuthInfo auth;
        render!("login.dt", error, auth);
    }

    @noAuth
    @errorDisplay!getLogin
    @path("/login")
    public void postLogin(ValidUsername username, string password,
            scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        enforce(username == "codemyst", "invalid username");
        enforce(password == "epik", "invalid password");

        AuthInfo s = { username: username };
        req.session = res.startSession();
        req.session.set("auth", s);
        redirect("./");
    }

    @anyAuth
    @path("/logout")
    public void getLogout()
    {
        terminateSession();
        redirect("./");
    }

    @noAuth
    @path("/*")
    @method(HTTPMethod.POST)
    public void del(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        auto path = req.requestPath.toString();
        auto fullpath = chainPath(filesPath, path[1..$]).array().decodeComponent();

        if (isDir(fullpath))
        {
            rmdirRecurse(fullpath);
        }
        else
        {
            remove(fullpath);
        }

        res.redirect(dirName(path));
    }

    @noAuth
    @path("/*")
    public void get(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        auto path = req.requestPath.toString();

        FileTree tree = getTree(path);

        enforceHTTP(tree !is null, HTTPStatus.notFound);

        if (tree.isDir)
        {
            Nullable!AuthInfo auth;
            if (req.session && req.session.isKeySet("auth"))
            {
                auth = req.session.get!AuthInfo("auth");
            }

            render!("index.dt", tree, auth);
        }
        else
        {
            auto np = NativePath(chainPath(filesPath, tree.path[1..$]).array().decodeComponent());
            sendFile(req, res, np);
        }
    }
}

public string byteToHumanReadable(ulong size, ulong decimals)
{
    import std.math : abs, pow, round;
    import std.conv : to;
    import std.string : format;

    if (size == 0)
    {
        return "0b";
    }

    const thresh = 1000;

    if (abs(size) < thresh)
    {
        return size.to!string() ~ "b";
    }

    const units = ["kb", "mb", "gb", "tb", "pb", "eb", "zb", "yb"];

    auto u = -1;
    const r = pow(10, decimals);

    // stupid dscanner warning
    auto ul = units.length;

    double s = size;

    do
    {
        s/= thresh;
        ++u;
    } while (round(abs(s) * r) / r >= thresh && u < ul - 1);

    string fmt = "%."~decimals.to!string()~"f"~units[u];
    return format(fmt, s);
}
