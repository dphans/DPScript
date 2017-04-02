#!/bin/bash
VERSION="1.0"
ERR=`tput setaf 1`
SCS=`tput setaf 2`
NON=`tput sgr0`

# project default values
APPNAME="dpscript"
APPVER="1.0.0"
APPAUTHOR="dphans"
APPAUTHORMAIL="baophan94@icloud.com"

clear
echo ╱╱${SCS}╭╮${NON}╱╱${SCS}╭━━━╮${NON}╱╱╱╱╱╱╱╱${SCS}╭╮${NON}
echo ╱╱${SCS}┃┃${NON}╱╱${SCS}┃╭━╮┃${NON}╱╱╱╱╱╱╱${SCS}╭╯╰╮${NON}
echo ${SCS}╭━╯┣━━┫╰━━┳━━┳━┳┳━┻╮╭╯${NON}
echo ${SCS}┃╭╮┃╭╮┣━━╮┃╭━┫╭╋┫╭╮┃┃${NON}
echo ${SCS}┃╰╯┃╰╯┃╰━╯┃╰━┫┃┃┃╰╯┃╰╮${NON}
echo ${SCS}╰━━┫╭━┻━━━┻━━┻╯╰┫╭━┻━╯${NON}
echo ╱╱╱${SCS}┃┃${NON}╱╱╱╱╱╱╱╱╱╱╱${SCS}┃┃ ${ERR}$VERSION${NON}
echo ╱╱╱${SCS}╰╯${NON}╱╱╱╱╱╱╱╱╱╱╱${SCS}╰╯${NON}
echo "Node.js project structure make it quickly"
echo "-------"

# collect app name
read -p "Enter your app name (${SCS}$APPNAME${NON}): " appname
if [[ -z "$appname" ]]; then
	echo "${ERR}> use default: " $APPNAME ${NON}
else
	APPNAME=$appname
fi

# collect app version
# TODO: Validate version like x.x.x
# read -p "Enter version (${SCS}$APPVER${NON}): " appver
# if [[ -z "$appver" ]]; then
# 	echo "${ERR}> use default: " $APPVER ${NON}
# else
# 	APPVER=$appver
# fi

# collect author
read -p "Author name (${SCS}$APPAUTHOR${NON}): " appauthor
if [[ -z "$appauthor" ]]; then
	echo "${ERR}> use default: " $APPAUTHOR ${NON}
else
	APPAUTHOR=$appauthor
fi

# collect author email
read -p "Enter author email (${SCS}$APPAUTHORMAIL${NON}): " appauthormail
if [[ -z "$appauthormail" ]]; then
	echo "${ERR}> use default: " $APPAUTHORMAIL ${NON}
else
	APPAUTHORMAIL=$appauthormail
fi

declare -a directories=(
	"$APPNAME"
	"$APPNAME/app"
	"$APPNAME/app/config"
	"$APPNAME/app/controllers"
	"$APPNAME/app/controllers/helpers"
	"$APPNAME/app/daos"
	"$APPNAME/app/daos/helpers"
	"$APPNAME/app/models"
	"$APPNAME/app/services"
	"$APPNAME/app/services/helpers"
	"$APPNAME/app/temps"
	"$APPNAME/app/utils"
	"$APPNAME/app/views"
	"$APPNAME/app/views/elements"
	"$APPNAME/app/views/layouts"
	"$APPNAME/app/views/pages"
	"$APPNAME/app/webroot"
	"$APPNAME/app/webroot/components"
	"$APPNAME/app/webroot/files"
	"$APPNAME/app/webroot/images"
	"$APPNAME/app/webroot/scripts"
	"$APPNAME/app/webroot/styles"
	"$APPNAME/scripts"
	"$APPNAME/scripts/db"
)

echo
read -r -p "Are you sure? [y/N] " confirm
case "$confirm" in
	[yY][eE][sS]|[yY])
	
	echo "marking directories..."
	for directory in "${directories[@]}"
	do
		echo "marking ${SCS}$directory${NON}..."
		mkdir $directory
	done

	echo "marking empty database with upgrade scripts table..."
	cat > $APPNAME/scripts/db/database.sql <<- "EOF"
		CREATE TABLE `upgrade_scripts` (
			`id` int(11) unsigned NOT NULL AUTO_INCREMENT,
			`file_name` varchar(128) NOT NULL DEFAULT '',
			`version` varchar(8) NOT NULL DEFAULT '',
			`created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
			`modified_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	EOF

	echo "marking main file (app.js)..."
	cat > $APPNAME/app.js <<- "EOF"
		global.CONFIG	= require('./app/config/config.js');
		var express 	= require('express');
		var app 		= express();
		var fileSystem	= require('fs');
		var jwt     	= require('jsonwebtoken');
		var bodyParser 	= require("body-parser");
		var cookieSession = require('cookie-session');
		var viewUtils	= require('./app/utils/ViewUtils.js');

		/* prepare files/direcotories */
		var directories = [
		__dirname + '/app/temps',
		__dirname + '/app/temps/logs'
		];
		directories.forEach(directory => {
			if (!fileSystem.existsSync(directory)) { fileSystem.mkdirSync(directory); };
			});

		/* config app */
		app.set('views', __dirname + global.CONFIG.APP.PATHS.VIEWS);
		app.set('view engine', 'pug');
		app.engine('pug', require('pug').__express);
		app.use(bodyParser.urlencoded({ extended: true }));
		app.use(bodyParser.json());
		app.use(express.static(__dirname + global.CONFIG.APP.PATHS.WEBROOT));
		app.use(cookieSession({
			name: 'session',
			secret: global.CONFIG.AUTHENTICATION.SECRET
		}));
		app.use(function(req, res, next) {
			var render = res.render;
			res.render = function(view, locals, cb) {
				if (typeof locals == 'object' && req.session && req.session.TOKEN) {
					var tokenData 		= jwt.verify(req.session.TOKEN, global.CONFIG.AUTHENTICATION.SECRET);
					locals.tokenData 	= tokenData || undefined;
					locals.utils 		= viewUtils;
				};
				render.call(res, view, locals, cb);
			};
			next();
		});

		/* routes the requests */
		require('./app/config/Routes.js')(app);

		/* start app */
		app.listen(global.CONFIG.APP.PORT, () => {
			console.log('server started at port ' + global.CONFIG.APP.PORT);
		});
	EOF

	echo "marking default bowers.json"
	cat > $APPNAME/bower.json <<-EOT
		{
		  "name": "$APPNAME",
		  "description": "",
		  "main": "app.js",
		  "authors": [
		    "$APPAUTHORMAIL"
		  ],
		  "license": "ISC",
		  "homepage": "",
		  "private": true,
		  "ignore": [
		    "**/.*",
		    "node_modules",
		    "bower_components",
		    "app/webroot/components/",
		    "test",
		    "tests"
		  ],
		  "dependencies": {
		    "jquery": "^3.2.1",
		    "uikit": "^3.0.0-Beta.18"
		  }
		}
	EOT

	echo "marking default npm dependencies file (package.json)..."
	cat > $APPNAME/package.json <<-EOT
		{
		  "name": "${APPNAME}",
		  "version": "${APPVER}",
		  "description": "",
		  "main": "app.js",
		  "scripts": {
		    "test": "echo \"Error: no test specified\" && exit 1"
		  },
		  "author": "$APPAUTHOR",
		  "license": "ISC",
		  "homepage": "",
		  "dependencies": {
		    "bcrypt": "^1.0.2",
		    "body-parser": "^1.16.1",
		    "cookie": "^0.3.1",
		    "cookie-session": "^2.0.0-beta.1",
		    "express": "^4.14.1",
		    "fs": "0.0.1-security",
		    "jsonwebtoken": "^7.3.0",
		    "mysql": "^2.13.0",
		    "pug": "^2.0.0-beta11",
		    "sequelize": "^3.30.2"
		  }
		}
	EOT

	echo "configuring bower default settings..."
	cat > $APPNAME/.bowerrc <<-EOT
		{
			"directory": "app/webroot/components/"
		}
	EOT

	echo "marking files..."
	cat > $APPNAME/app/config/Config.js <<-EOT
		const Config = {

			APP: {
				PORT: 5000,
				PATHS: {
					VIEWS: "/app/views",
					WEBROOT: "/app/webroot"
				}
			},

			AUTHENTICATION: {
				SECRET: "$APPAUTHORMAIL"
			},

			PUBLIC: {
				TITLE: "$APPNAME"
			}

		};
		module.exports = Config;
	EOT

	cat > $APPNAME/app/config/Routes.js <<-EOT
		var Pages 	= require('../controllers/Pages.js');

		module.exports = function (app) {

			app.use('/pages', Pages);
			app.use('/', Pages.get('/'));

		};
	EOT

	cat > $APPNAME/app/controllers/Pages.js <<-EOT
		var express = require('express');
		var Pages 	= express.Router();

		Pages.get('/', (request, response) => {
			response.render('pages/index.pug');
		});

		module.exports 	= Pages
	EOT

	cat > $APPNAME/app/utils/ViewUtils.js <<-EOT
		const ViewUtils = {

		};

		module.exports 	= ViewUtils;
	EOT

	cat > $APPNAME/app/views/elements/scripts.default.pug <<-EOT
		script(type= 'text/javascript', src= '/components/jquery/dist/jquery.min.js')
		script(type= 'text/javascript', src= '/components/uikit/dist/js/uikit.min.js')
		script(type= 'text/javascript', src= '/scripts/commons.default.js')
	EOT

	cat > $APPNAME/app/views/elements/styles.default.pug <<-EOT
		link(rel= 'stylesheet', href= '/components/uikit/dist/css/uikit.min.css')
		link(rel= 'stylesheet', href= '/styles/commons.default.css')
	EOT

	cat > $APPNAME/app/views/layouts/default.pug <<-EOT
		html
			head
				meta(charset= 'utf-8')
				meta(name= 'viewport', content= 'width=device-width,initial-scale=1')
				title= title || CONFIG.PUBLIC.TITLE
				block styles
					include ../elements/styles.default.pug
				block scripts
					include ../elements/scripts.default.pug
			body
				block header
				block content
				block footer
	EOT

	cat > $APPNAME/app/views/pages/index.pug <<-EOT
		include ../layouts/default.pug

		content
			article(class= 'uk-article')
				h2 $APPNAME
				p App now running
				p
					small thanks for using DPScript
					br
					small please help we optimize this project structure at:
					span &nbsp;
					a(href= 'https://github.com/dphans') my github page

	EOT

	cat > $APPNAME/app/webroot/scripts/commons.default.js <<-EOT
		
	EOT

	cat > $APPNAME/app/webroot/styles/commons.default.css <<-EOT
		body {
			position: relative;
			padding: 16px;
		}

		article {
			color: #222;
		}

		article > h2 {
			font-size: 48px;
			margin-bottom: 0px;
		}

		article > p {
			margin-top: 0px;
			font-size: 18px;
		}
	EOT

	cd $APPNAME
	bower install
	npm install

	echo "Mmmmm"
	echo "All things done"
	node app.js

		;;
	*)
	exit 1
	;;
esac
