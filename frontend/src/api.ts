export interface FileInfo {
  name: string;
  size: number;
  last_modified: string;
  is_dir: boolean;
}

export const login = async (username: string, password: string): Promise<boolean> => {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/login`, {
    method: 'post',
    body: JSON.stringify({ username, password })
  });

  if (res.ok) {
    const json = await res.json();
    localStorage.setItem('filemyst-token', json['access_token']);
  }

  return res.ok;
};

export const getFiles = async (basePath: string): Promise<FileInfo[]> => {
  const token = localStorage.getItem('filemyst-token');

  const res = await fetch(`${import.meta.env.VITE_API_URL}/${basePath}`, {
    headers: {
      ...(token && { 'Authorization': `Bearer ${token}` })
    }
  });

  return await res.json();
};

export const deleteFile = async (path: string) => {
  const token = localStorage.getItem('filemyst-token');

  if (!token) {
    return;
  }

  await fetch(`${import.meta.env.VITE_API_URL}/${path}`, {
    method: 'delete',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
};

export const renameFile = async (path: string, newName: string) => {
  const token = localStorage.getItem('filemyst-token');

  if (!token) {
    return;
  }

  await fetch(`${import.meta.env.VITE_API_URL}/${path}?new_name=${newName}`, {
    method: 'put',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
};
