# A script that checks for Nginx Proxy Manager hosts that are down

Written in Bash

# Usage

- Run it
  ```sh
  ./foo.sh
  ```
- Example output
  ```txt
  
  ```

# Dependencies

- jq
- curl
- Bash

# Setup

- Get your authorization key header for the Nginx Proxy Manager API.
(Not sure how you're supposed to get it, but this is how I did)
  - Open the Nginx Proxy Manager webpage
  - Open inspect element (`ctrl`+`shift`+`i`) and go to the "Console" tab
  - Click on "Proxy Hosts"
  ![screenshot of element](img/proxy-hosts.png)
  - On the inspect element window, there should be a new XHR request with a url similar to this (obviously, with your domain name)
  ![screenshot of inspect element XHR request](img/xhr-req-npm-api.png)
  - Click on that XHR request and find the `Authorization` request header
  - Copy the full value of the header
  - Create a `.env` file in the directory of the script, and paste it into the file like as the value of `Authorization`, then add the url for the api endpoint as the value of `apiEndPoint`. Example (not the actual length of a valid value):
  ```env
  Authorization="Bearer hgjdfghdfjkghjdfiogjr"
  apiURL="https://nginx.my-lan.dev/api/nginx/proxy-hosts"
  ```
- Download the script (replace `wget` with your prefered command, and set the output to a different file name if you can think of a good name, because I couldn't)
  ```sh
  wget https://github.com/Supraboy981322/misc-scripts/check-nignx-proxy-manager-hosts/src/foo.sh
  ```
- Make the script executable (replace `foo.sh` if you changed the output file name)
  ```sh
  chmod a+x foo.sh
  ```
