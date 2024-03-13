import { error } from '@sveltejs/kit';
import { fileExists, readFile } from '../../files';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = ({ url }) => {
    if (!fileExists(url.pathname)) error(404);

    return new Response(readFile(url.pathname));
};
