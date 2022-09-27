import std.stdio: writef, writefln, readln;
import std.getopt: getopt, GetoptResult, config;
import std.array: popFront, join;
import std.file: readText, exists, isFile, rmdirRecurse, mkdirRecurse, remove;
import std.path: buildNormalizedPath, absolutePath, isValidPath;
import std.process: execute, environment, executeShell;
import std.conv: to;

import sily.getopt;

int main(string[] args) {
    bool gd3 = false;
    bool gd4 = false;

    GetoptResult helpInfo = getopt(
        args, 
        config.passThrough,
        "gd3", "Initialise Godot 3 project", &gd3,
        "gd4", "Initialise Godot 4 project, default", &gd4
    );

    string[] nargs = args.dup;
    nargs.popFront();
    string file = nargs.join();

    if (helpInfo.helpWanted) {
        Commands[] com = [];
        printGetopt("", "gdhelper [options] [path]", com, helpInfo.options);
        return 0;
    }

    if (!gd3 && !gd4) {
        gd4 = true;
    }

    if (gd3 && gd4) {
        gd3 = false;
    }

    string path = file.buildNormalizedPath.absolutePath;

    if (path == "") {
        writefln("Please supply project path.");
        return 1;
    }

    if (!path.isValidPath) {
        writefln("Path \"%s\" is not valid.", path);
        return 1;
    }

    if (gd4) {
        writefln("Initialising Godot 4 project.");
    } else {
        writefln("Initialising Godot 3 project.");
    }

    if (!path.exists) {
        writefln("Creating directory at \"%s\".", path);
        mkdirRecurse(path);
    } else {
        writefln("Directory at \"%s\" already exists, delete contents?", path);
        while (true) {
            writef("[y/n]: ");
            string answ = readln();
            if (answ == "y\n" || answ == "Y\n") {
                version(Windows) {
                    executeShell(`rmdir /S /Q "` ~ path ~ `"`);
                } else {
                    executeShell(`rm -rf '` ~ path ~ `'`);
                }
                mkdirRecurse(path);
                break;
            }
            if (answ == "n\n" || answ == "N\n") {
                writefln("Aborting. Directory must be empty.");
                return 0;
            }
        }
    }

    if (path.isFile) {
        writefln("\"%s\" is a file.", path);
        return 1;
    }

    string repo = gd4 ? "git@github.com:al1-ce/godot-4-init.git" : "git@github.com:al1-ce/godot-3-init.git";

    auto exec = execute(["git", "clone", repo, path]);
    if (exec.status != 0) { 
        writefln("Failed to git clone \"%s\".", repo); 
        if ((path ~ "/.git/").buildNormalizedPath.exists) {
            writefln("Project directory must not contain git repository.");
        } else {
            writefln("Check if git is installed and has SSH key attached.");
        }
        return 1;
    }

    string gitpath = (path ~ "/.git/").buildNormalizedPath;
    string licencepath = (path ~ "/LICENSE").buildNormalizedPath;

    if (gitpath.exists && !gitpath.isFile) {
        version(Windows) {
            executeShell(`rmdir /S /Q "` ~ gitpath ~ `"`);
        } else {
            executeShell(`rm -rf '` ~ gitpath ~ `'`);
        }
    }

    if (licencepath.exists && licencepath.isFile) {
        remove(licencepath);
    }

    mkdirRecurse( buildNormalizedPath(path ~ "/assets/components/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/fonts/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/materials/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/models/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/resources/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/shaders/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/sounds/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/sprites/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/textures/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/assets/tbmaps/") );

    mkdirRecurse( buildNormalizedPath(path ~ "/lib/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/scenes/") );
    mkdirRecurse( buildNormalizedPath(path ~ "/scripts/") );

    writefln("Project successfully initialised.");

    return 0;
}
