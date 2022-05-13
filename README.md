### This Repo will be Read Only in 2023

https://github.com/actions/cache/issues/505#issuecomment-1123435993

### Dependency cache installation for Github Enterprise - self hosted runners

https://medium.com/web-developer/github-actions-solving-actions-cache-v2-for-self-hosted-runners-on-github-enterprise-663f22caeee3
### Server Setup

https://github.com/kevincobain2000/cache-http
### Installation

```
    - name: Yarn Install (with cache)
      uses: kevincobain2000/action-cache-http@v3
      with:
        version: ${{ matrix.node-versions }}
        lock_file: yarn.lock
        install_command: yarn install
        destination_folder: node_modules
        // Speed up caching at the cost of more storage space
        disable_compression: true
        operating_dir: "./" # optional
        cache_http_api: "https://yourdomain.com/path/to/installation/cache-http"
        http_proxy: ""
```
