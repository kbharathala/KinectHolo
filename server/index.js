var http = require('http');
var fs = require('fs');
var url = require('url');
var spawn = require("child_process").spawn;
let path = require('path')
let express = require('express');
let app = express();
let publicFolderName = '../common';
app.use(express.static(publicFolderName));

// For potential future use
let ProtoBuf = require('protobufjs');
let builder = ProtoBuf.loadProtoFile(
  path.join(__dirname,
  publicFolderName,
  'message.proto')
);
let Message = builder.build('Message');

 // fs.readFile("proto", function(err, data) {
 //    if (err) {
 //      res.writeHead(404, {'Content-Type': 'text/html'});
 //      return res.end("404 Not Found");
 //    }
 //    new Message.decodeDelimited(data).encode().toBuffer();
 //  });

app.get('/allmessages', (req, res, next)=>{
  fs.readdir('files', function(err, items) {
    res.setHeader('Content-Type', 'application/json');
    res.write(JSON.stringify(items));
    res.end();
  });
});

app.get('/messages/:name', (req, res, next)=>{
  var filename = 'files/' + req.params.name;
  console.log(filename);
  fs.readFile(filename, function(err, data) {
    if (err) {
      res.writeHead(404, {'Content-Type': 'text/html'});
      return res.end("404 Not Found");
    }
    res.writeHead(200, {'Content-Type': 'text/json'});
    res.write(data);
    return res.end();
  });
})

app.post('/newmessage/:name', (req, res, next)=>{
  if (req.raw) {
    try {
      // let msg = new Message(req.raw).encode().toBuffer();
      fs.writeFile("files/" + req.params.name, req.raw, function(err) {
        if(err) {
            return console.log(err);
        }
      }); 
    } catch (err) {
      console.log('Processing failed:', err);
      next(err);
    }
  } else {
    console.log("Not binary data");
  }
});

app.get('/testing/:name', (req, res, next)=>{
  // var pr = spawn('python',["test.py", req.params.name]);
  // console.log(req.params.name);
  // pr.stdout.on('data', function (data) {
  //   console.log(data.toString());
  // });
  // pr.stdout.on('end', function () {
  //   console.log(data.toString());
  // });
});

app.all('*', (req, res)=>{
  res.status(400).send('Not supported');
});

app.listen(3000);
