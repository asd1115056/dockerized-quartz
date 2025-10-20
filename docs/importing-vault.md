## Mounting the Vault as a Volume

The container path of the Obsidian vault is located at `/vault`. If no volume bind is provided, the container will copy example documentation to `/vault`, allowing it to be used as a demonstration.

The recommended way to provide the Obsidian vault to the container is by using a bind-mount volume:

```sh
-v /path/on/host:/vault:ro
```

**Note**
When possible use the `:ro` (read-only) flag to prevent unintentional modifications to the vault from within the container.

## Updating the Vault

There are two main methods to update the vault contents: **External Updates** and **Git-based Updates**.

### 1. External Updates

If you are using an external tool such as **Syncthing**, **direct editing with Obsidian**, or any other synchronization method, you can trigger a rebuild of the Quartz site through an **auto-rebuild mechanism**, a **cron job**, or a **webhook**.

#### Example: Syncthing Setup

- Syncthing can sync the entire Obsidian vault to a directory, e.g., `/home/user/Obsidian/`.
- Bind volume to container `-v /home/user/Obsidian:/vault:ro`
- Quartz will detect changes when syncthing syncs and execute rebuild
- If auto update (detect on file changes) is disabled, cronjob or webhook can be used to execute update. 

[Post Webhook Plugin](https://github.com/Masterb1234/obsidian-post-webhook/) can be useful for this scenario.

### 2. Git-based Updates

If your Obsidian vault is hosted in a Git repository (e.g., **GitHub**), follow these steps:

1. Prepare the vault folder on the host machine:
   ```sh
   mkdir /path/on/host/vault
   ````
2. Perform an initial Git clone or pull into this folder:
   ```sh
   git clone <your-repo-url> /path/on/host/vault
   ```
3. Set the environment variable to enable automatic Git pulls:
   ```sh
   VAULT_DO_GIT_PULL_ON_UPDATE=true
   ```
4. Choose an update strategy:
   - **Cron job**: Schedule periodic updates
   - **Webhook**: Trigger rebuilds on repository changes

Before rebuilding, the container will execute a `git pull` inside `/vault` to fetch the latest changes.

**Note**:
When using Git-based updates volume **needs** read-write permissions to execute `git pull`. Mount volume with `/path/on/host/git_vault:/vault` without the `:ro` flag.

#### Authenticating with Private Repositories

If your vault is stored in a **private GitHub repository**, you'll need to provide a Personal Access Token for authentication.

##### Setup Steps

1. **Generate a GitHub Personal Access Token:**
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Select scope: `repo` (Full control of private repositories)
   - Copy the generated token (starts with `ghp_`)

2. **Configure environment variables in your .env file:**
   ```sh
   VAULT_DO_GIT_PULL_ON_UPDATE=true
   VAULT_GIT_USERNAME=your-github-username
   VAULT_GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
   ```

3. **Clone your vault repository using HTTPS:**
   ```sh
   git clone https://github.com/username/private-vault.git /path/on/host/vault
   ```

4. **Mount the vault in docker-compose.yml:**
   ```yaml
   volumes:
     - /path/on/host/vault:/vault
   ```

**Security Note:** Never commit your `.env` file to version control. Add it to `.gitignore`.