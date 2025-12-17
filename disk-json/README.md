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

  ```
