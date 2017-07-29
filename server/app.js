var http = require('http');
var fs = require('fs');
var url = require('url');

var app = http.createServer(function(req,res){
  var q = url.parse(req.url, true);
  console.log(q.path);

  if (q.path == '/' || q.path == 'files') {
    fs.readdir('files' + q.path, function(err, items) {
      res.setHeader('Content-Type', 'application/json');
      res.write(JSON.stringify(items));
      res.end()
    });
  } else {

    var filename = 'files' + q.path;

    fs.readFile(filename, function(err, data) {
      if (err) {
        res.writeHead(404, {'Content-Type': 'text/html'});
        return res.end("404 Not Found");
      }  
      res.setHeader('Content-Type', 'application/json');
      res.write(data);
      return res.end();
    });
  }
});
app.listen(3000);
