var express		 		= require('express'),
	path 				= require('path'),
	bodyParser 			= require('body-parser'),
	MongoClient 		= require('mongodb').MongoClient,
	Server 				= require('mongodb').Server,
	CollectionDriver 	= require('./collectionDriver').CollectionDriver;

var app = express();

app.set('port', process.env.PORT || 3000);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

var mongoHost = 'localHost';
var mongoPort = 27017;
var collectionDriver;

app.use(bodyParser.json());

var mongoClient = new MongoClient(new Server(mongoHost, mongoPort));
mongoClient.open(function(err, mongoClient) {
	if(!mongoClient) {
		console.error("error! exiting must start mongo first");
		process.exit(1);
	}	
	var db = mongoClient.db("MyDatabase");
	collectionDriver = new CollectionDriver(db);
})

app.use(express.static(path.join(__dirname, 'public')));

app.get('/:collection', function(req,res) {
	var params = req.params;
	collectionDriver.findAll(req.params.collection, function(error, objs){
		if (error) { res.send(400, error); }
		else {
			if (req.accepts('html')) {
				res.render('data', {objects: objs, collection: req.params.collection});
			} else {
				res.set('Content-Type','application/json');
				res.send(200,objs);
			}
		}
	});
});

app.get('/:collection/:entity', function(req,res) {
	var params = req.params;
	var entity = params.entity;
	var collection = params.collection;
	if (entity) {
		collectionDriver.get(collection,entity,function(error,objs) {
			if (error) { res.send(400, error); }
			else { res.send(200,objs); }
		});
	} else {
		res.send(400, {error: 'bad url', url:req.url});
	}
});

app.post('/:collection', function(req,res) {
	var object = req.body;
	var collection = req.params.collection;
	collectionDriver.save(collection,object, function(err,docs) {
		if (err) { res.send(400,err); }
		else { res.send(201, docs); }
	});
});

app.put('/:collection/:entity', function(req,res) {
	var params = req.params;
	var entity = params.entity;
	var collection = params.collection;
	if (entity) {
		collectionDriver.update(collection, req.body, entity, function( error, objs) {
			if (error) { res.send(400,error); }
			else { res.send(200, objs); }
		});
	} else {
		var error = {"message" : "Cannot PUT a whole collection"};
		res.send(400,error);
	}
});

app.delete('/:collection/:entity', function(req, res) {
	var params = req.params;
	var entity = params.entity;
	var collection = params.collection;
	if(entity) {
		collectionDriver.delete(collection, entity, function(error,objs){
			if (error) { res.send(400,error); }
			else { res.send(200,objs); }
		});
	} else {
		var error = {"message" : " Cannot DELETE a whole collection"};
		res.send(400,error);
	}
});

app.use(function(req, res) {
	res.render('404', {url: req.url});
});

app.listen(app.get('port'), function() {
	console.log('server listening on port '+app.get('port'));
});