# Q&A / Troubleshooting

## n8n `Read/Write Files from Disk` says “not writable”

### Symptom

- Error like:
  - `NodeApiError: The file "/files/..." is not writable`
  - or `The file "/home/node/files" is not writable`

### Root cause

This can happen even when the container user **can** write at the OS level.

In addition to Linux/Docker permissions, n8n applies an **application-level file access restriction** for safety. When the target path is outside the allowed base directories, n8n blocks the write and reports it as “not writable”.

### Fix used (recommended)

1. Write only inside the mounted directory (in this repo it’s `/files`):
   - Good: `/files/audios/output.wav`
   - Not recommended: `/home/node/files/...` (unless you explicitly mount to that location)

2. Allow n8n file access to `/files`:
   - Add this to the `n8n` service `environment:` in `docker-compose.yaml`:
     - `N8N_RESTRICT_FILE_ACCESS_TO=/files`

3. Restart:
   - `docker compose down`
   - `docker compose up -d`

4. Ensure the host folder exists (these map to your laptop):
   - `./files` and any subfolders you write to (e.g. `./files/audios`)

### How we verified it was not a permissions problem

Inside the running container, we validated the `node` user can write to `/files`:

```bash
docker compose exec n8n sh -lc 'id && ls -la /files && touch /files/audios/_write_test && ls -la /files/audios/_write_test'
```

If `touch` works but the node fails, it’s almost always the n8n restriction described above.

---

## Alternative fixes (when appropriate)

### 1) Mount the host folder to the path you want to use

If you prefer writing to `/home/node/files/...`, change the compose mount to:

- `./files:/home/node/files`

This is simple, but you should still keep the n8n restriction aligned (allow that base path).

### 2) Allow a broader set of paths

You can set `N8N_RESTRICT_FILE_ACCESS_TO` to a broader base (or multiple bases, depending on your n8n version/config). This reduces friction but is **less secure**, because workflows can access more of the container filesystem.

### 3) Fix host-side permissions (only when `touch` fails)

If the container can’t write to `/files` at all, fix the host folder ownership/permissions:

```bash
sudo mkdir -p files/audios
sudo chown -R 1000:1000 files
sudo chmod -R u+rwX,g+rwX files
```

On macOS + Docker Desktop, you may also need to ensure Docker Desktop has file sharing enabled for the repo path.

### 4) Run the container as `root` (not recommended)

Setting `user: root` can bypass some permission issues, but it can also create **root-owned files** in bind-mounted folders (`n8n_data`, `files`) which can cause future permission problems. Prefer fixing the mount path, `N8N_RESTRICT_FILE_ACCESS_TO`, and host permissions instead.

