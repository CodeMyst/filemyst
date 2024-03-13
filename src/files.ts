import { PUBLIC_FILES_PATH } from '$env/static/public';
import fs from 'fs';

export interface FileEntry {
    isDir: boolean;
    name: string;
}

export const isDir = (path: string): boolean => {
    return fs.lstatSync(`${PUBLIC_FILES_PATH}/${decodeURIComponent(path)}`).isDirectory();
};

export const isFile = (path: string): boolean => {
    return fs.lstatSync(`${PUBLIC_FILES_PATH}/${decodeURIComponent(path)}`).isFile();
};

export const fileExists = (path: string): boolean => {
    return fs.existsSync(`${PUBLIC_FILES_PATH}/${decodeURIComponent(path)}`);
};

export const readFile = (path: string) => {
    return fs.readFileSync(`./files${decodeURIComponent(path)}`);
};

export const getEntries = (path: string): FileEntry[] => {
    return fs.readdirSync(`${PUBLIC_FILES_PATH}/${decodeURIComponent(path)}`).map((f) => (
        {
            isDir: isDir(f),
            name: f
        }
    ));
};
