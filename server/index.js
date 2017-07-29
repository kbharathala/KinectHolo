var http = require('http');
var fs = require('fs');
var url = require('url');
let path = require('path')
let express = require('express')
let app = express()
let publicFolderName = 'public'
app.use(express.static(publicFolderName))

// For potential future use
let ProtoBuf = require('protobufjs')
let builder = ProtoBuf.loadProtoFile(
  path.join(__dirname,
  publicFolderName,
  'message.proto')
)
let Message = builder.build('Message')

app.get('/allmessages', (req, res, next)=>{
  fs.readdir('files', function(err, items) {
    res.setHeader('Content-Type', 'application/json');
    res.write(JSON.stringify(items));
    res.end()
  });
})

app.get('/messages/:name', (req, res, next)=>{
  var filename = 'files/' + req.params.name;
  console.log(filename);
  fs.readFile(filename, function(err, data) {
    if (err) {
      res.writeHead(404, {'Content-Type': 'text/html'});
      return res.end("404 Not Found");
    }  
    res.write(data);
    return res.end();
  });
})

app.all('*', (req, res)=>{
  res.status(400).send('Not supported')
})

app.listen(3000)
