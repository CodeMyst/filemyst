import type { ParamMatcher } from '@sveltejs/kit';
import { fileExists, isDir } from '../files';
import { browser } from '$app/environment';

export const match: ParamMatcher = (param) => {
    if (browser) return false;

    if (!fileExists(param)) return false;

    return isDir(param);
};
