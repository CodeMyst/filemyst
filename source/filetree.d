import std.string;
import std.path;
import std.array;
import std.stdio;
import std.datetime;

public class FileTree
{
    public string name;
    public string path;
    public ulong rawsize;
    public string prettysize;
    public bool isDir;
    public SysTime lastModified;
    public FileTree parent;
    public FileTree[] subtree;

    public void add(FileTree sub)
    {
        sub.parent = this;
        subtree ~= sub;
    }
    public void sort()
    {
        import std.algorithm : sort;

        subtree.sort!((a, b) => a.compare(b) < 0);
    }

    public int compare(FileTree other)
    {
        import std.algorithm : cmp;

        import std.string : startsWith;

        if (this.isDir && !other.isDir)
        {
            return -1;
        }
        else if (!this.isDir && other.isDir)
        {
            return 1;
        }

        if (this.name.startsWith(".") && !other.name.startsWith("."))
        {
            return -1;
        }
        else if (!this.name.startsWith(".") && other.name.startsWith("."))
        {
            return 1;
        }

        return cmp(this.name, other.name);
    }
}

