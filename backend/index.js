import http from 'http';
import PG from 'pg';
import promclient from 'prom-client'

const port = process.env.PORT;
const user = process.env.DB_USER;
const pass = process.env.DB_PASSWORD
const host = process.env.HOST
const db_port = process.env.DB_PORT

const counter = new promclient.Counter({
  name: "node_requests_total",
  help: "total requests",
})

const httpStatusCounter = new promclient.Counter({
  name: 'http_responses_total',
  help: 'Total number of HTTP responses by status code',
  labelNames: ['status_code']
});

const client = new PG.Client(
  `postgres://${user}:${pass}@${host}:${db_port}/postgres` 
);

let successfulConnection = false;

http.createServer(async (req, res) => {
  console.log(`Request: ${req.url}`);

  if (req.url === "/api") {
    client.connect()
      .then(() => { successfulConnection = true; console.log('Database connected')})
      .catch(err => console.error('Database not connected -', err.stack));

    res.setHeader("Content-Type", "application/json");
    res.writeHead(200);

    let result;

    try {
      result = (await client.query("SELECT * FROM users")).rows[0];
    } catch (error) {
      console.error(error)
    }

    const data = {
      database: successfulConnection,
      userAdmin: result?.role === "admin"
    }

    counter.inc()
    httpStatusCounter.inc({
      status_code: res.statusCode
    })
    res.end(JSON.stringify(data));
    
  } else if (req.url === "/metrics") {
    res.setHeader('Content-Type', promclient.register.contentType)
    res.end(await promclient.register.metrics())
  } else {
    counter.inc()
    res.writeHead(503);
    httpStatusCounter.inc({
      status_code: res.statusCode
    })
    res.end("Internal Server Error");
  }

}).listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});