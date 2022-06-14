# AFL Footy Stats

An application for data analysis of AFL fantasy football statistics.

## Development

Requirements: Docker, Node

For local development, run applications in Docker containers using the following step:

- Set Node version to 16.15 (run `nvm use` in root)
- Run `yarn build` to compile applications
- Run `docker compose build` to build Docker images
- Run `docker compose up` to run the images
- Local web app should now be running on <http://localhost> and Dynamo DB should be running on <http://localhost:8000>
- Local Dynamo DB data will be persisted in the `./dynamodb-data` directory
