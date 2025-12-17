# disk-json

A crappy disk statistics http server that returns json

---

# Basically...

- It's a single-purpose http server
- When it recieves a request
  - It runs the os command `sh -c df -h` (the crappy part)
  - Then parses it to create a JSON array of objects
  - Then returns the JSON to the client. Eg:
  ```json
  [
    {
      "Filesystem": "/dev/nvme0n1p2",
      "Size": "959267084",
      "Used": "483228852",
      "Avail": "427236380",
      "Use%": "54%",
      "Mounted on": "/"
    },
    {
      "Filesystem": "/dev/sdb1",
      "Size": "3844549616",
      "Used": "3006689576",
      "Avail": "642492824",
      "Use%": "83%",
      "Mounted on": "/mnt/Games"
    },
    {
      "Filesystem": "super@dev:/home/super",
      "Size": "32716560",
      "Used": "8935216",
      "Avail": "22087240",
      "Use%": "29%",
      "Mounted on": "/home/super/machines/dev"
    },
  ]
  ```
