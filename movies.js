var fs = require('fs');
var path = require('path');
var readline = require('readline');
var http = require('http');

var inputDir = './movies_unsorted';
var outputDir = './movies';

var createDir = function (path, mask, cb) {
	if (typeof mask == 'function') {
		cb = mask;
		mask = 0777;
	}
	fs.mkdir(path, mask, function(err) {
		if (err) {
			if (err.code == 'EEXIST') cb(null);
			else cb(err);
		} else cb(null);
	});
};

var readNfo = function (file, callback) {

	var nfo = {};

	var rd = readline.createInterface({
		input: fs.createReadStream(file),
		output: process.stdout,
		terminal: false
	});

	rd.on('line', function(line) {
		var lineArr = line.split(': ');
		if (lineArr.length > 1) {
			nfo[lineArr[0]] = lineArr[1].trim();
		}
	});

	rd.on('close', function() {
		callback(nfo);
	});

};

var featchImdbInfo = function (imdbId, callback) {
	var req = http.get({
		host: 'www.omdbapi.com',
		path: '/?i=' + imdbId + '&plot=short&r=json'
	}, function (res) {
		res.setEncoding('utf8');
		var output = '';
		res.on('data', function (chunk) {
			output += chunk;
		}).on('end', function () {
			var obj = JSON.parse(output);
			callback(null, obj);
		});
	});
	req.on('error', function (e) {
		callback(e);
	});
};

var moveRename = function (oldName, newName, dirName) {
	oldName = path.basename(oldName, '.nfo');
	fs.readdir(inputDir, function (err, files) {
		files.filter(function (fileName) {
			return (fileName.substr(0, fileName.lastIndexOf('.')) == oldName);
		}).forEach(function (fileName) {
			var source = inputDir + '/' + fileName;
			var ext = path.extname(source);
			var dest = outputDir + '/' + dirName + '/' + newName + ext;
			fs.rename(source, dest, function (err) {
				console.log('Moving file...');
				console.log('From: %s', source);
				console.log('To: %s', dest);
				if (err) {
					console.log('Failed' + '\n');
				} else {
					console.log('Success' + '\n');
				}
			});
		});
	});
};

fs.readdir(inputDir, function (err, files) {
	files.filter(function (fileName) {
		var regexp = /.*.nfo$/i;
		return regexp.test(fileName);
	}).forEach(function (fileName) {

		readNfo(inputDir + '/' + fileName, function (nfo) {
			if (nfo['imdb_com']) {
				var matches = nfo['imdb_com'].match(/tt[0-9]+/g);
				var imdbId = matches[0];
				featchImdbInfo(imdbId, function(err, info) {
					var dirName = info['Title'] + ' (' + info['Year'] + ')';
					createDir(outputDir + '/' + dirName, function(err) {
						if (err) {
							console.log('Could not create dir: %s' + '\n', dir);
							return;
						}
						console.log('Dir created: %s' + '\n', dirName);
						moveRename(fileName, info['Title'] + ' (' + info['Year'] + ')', dirName);
					});
				});
			} else {
				console.log('Could not find imdb URL in .nfo file: %s' + '\n', fileName);
			}
		});

	});
});