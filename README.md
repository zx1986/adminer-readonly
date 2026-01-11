# adminer-readonly

demo for a read-only adminer

- How to customize adminer docker image: https://github.com/docker-library/docs/tree/master/adminer

## Testing

Run the automated login test:

```bash
./test-login.sh
```

This script verifies that the `login-predefined` plugin correctly authenticates using the predefined credentials (adminer/adminer) from environment variables.

## Current Version

- Adminer: 5.4.1
- MariaDB: 10.6.19-focal
