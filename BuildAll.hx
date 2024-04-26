function main() {
	var blacklist:Array<String> = ['assets', 'dist', 'scratch', 'other-shapes', 'net'];
	var projects:Array<String> = [];
	var apps:Array<ApplicationConfig> = [];

	var args = Sys.args();
	if(args.length < 2){
		trace('Insufficient arguments; need source and destination path');
		return;
	}

	var source_path = args[0];
	var destination_path = args[1];
	var is_build_existing_js = false;

	if(args.length >= 2 && args[2] == "rebuild"){
		is_build_existing_js = true;
	}

	recurse_project_paths(projects, source_path, blacklist);
	#if debug
	trace('\n source: $source_path \n destination $destination_path \n (re)build all ? $is_build_existing_js');
	trace('Paths with project.xml: \n' + projects.join('\n'));
	#end

	for (path in projects) {
		recurse_applications(path, destination_path, apps);
	}

	#if debug
	var app_debug = [
		for (app in apps)
			' project path: ${app.project_path}\n main path:${app.main_path}\n main route: ${app.main_route}\n destination path: ${app.destination_path}'
	];
	trace('Applications to build: ' + app_debug.join('\n\n'));
	#end

	for (config in apps) {
		var project_path = haxe.io.Path.join(config.main_route.slice(0, config.main_route.length - 2)) + '/project.xml';
		var main_file_name = config.main_route[config.main_route.length - 1];
		var app_name = main_file_name.substring(0, main_file_name.length - 3);
		trace('Application $main_file_name from $project_path ($app_name)');

		var app_route = config.main_route.slice(1, config.main_route.length - 2);
		app_route.push(app_name);

		var app_path = config.destination_path;
		var js_path = '$app_path/html5/bin/Main.js';
		var is_js_exists = sys.FileSystem.exists(js_path);

		var is_compiling = true;
		if (is_js_exists) {
			trace('Already exists at $js_path');
			is_compiling = is_build_existing_js;
		}

		if (is_compiling) {
			var build_args = [
				'build',
				'/$project_path',
				'html5',
				'--app-main="$app_name"',
				'--app-path="$app_path"',
				// '-debug', // todo ? arg for building js debug files?
				'-D no-deprecation-warnings',
			];

			#if debug
			trace('args ' + build_args);
			#end

			trace('Building...');
			var exit_code = Sys.command('lime', build_args);

			if (exit_code == 0) {
				// generate index page for easier navigation
				var html_path = app_path + '/index.html';
				sys.io.File.saveContent(html_path, generate_project_index_html('800', '600'));
			} else {
				trace('Error $exit_code');
			}
		} else {
			trace('Did not build.');
		}
		trace('\n');
	}
}

function recurse_project_paths(projects:Array<String>, path:String, blacklist:Array<String>) {
	if (sys.FileSystem.exists(path)) {
		var directory_files = sys.FileSystem.readDirectory(path);

		if (directory_files.contains('project.xml')) {
			projects.push(path);
		} else {
			for (file_name in directory_files) {
				var sub_path = haxe.io.Path.join([path, file_name]);

				if (sys.FileSystem.isDirectory(sub_path) && !blacklist.contains(file_name)) {
					recurse_project_paths(projects, sub_path, blacklist);
				}
			}
		}
	} else {
		trace('"$path" does not exists');
	}
}

function recurse_applications(path:String, destination_path:String, hx_paths:Array<ApplicationConfig>) {
	if (sys.FileSystem.exists(path)) {
		var directory_files = sys.FileSystem.readDirectory(path);
		for (file in directory_files) {
			var sub_path = haxe.io.Path.join([path, file]);
			if (sys.FileSystem.isDirectory(sub_path)) {
				recurse_applications(sub_path, destination_path, hx_paths);
			} else {
				var sub_path_parts = sub_path.split('/').slice(1);
				var file_parts = file.split('.');
				var html_route = sub_path_parts.slice(4, sub_path_parts.length - 2);
				html_route.insert(0, destination_path);
				var html_path = haxe.io.Path.join(html_route);
				if (file_parts[1] != null && file_parts[1] == 'hx') {
					if (file_parts[0] == 'Main') {
						// definitely build it
						hx_paths.push({
							project_path: path,
							main_path: sub_path,
							main_route: sub_path_parts,
							destination_path: html_path
						});
					} else {
						// check to see if the file contains an Application
						if (StringTools.contains(sys.io.File.getContent(sub_path), 'extends Application')) {
							hx_paths.push({
								project_path: path,
								main_path: sub_path,
								main_route: sub_path_parts,
								destination_path: html_path
							});
						}
					}
				}
			}
		}
	} else {
		trace('"$path" does not exists');
	}
}

function generate_project_index_html(width:String, height:String):String {
	return '
<!DOCTYPE html>
<html>
	<head>
	</head>
	<body>
		<iframe src="html5/bin/" width="$width" height="$height"></iframe>
	</body>
</html>
	';
}

@:structInit
@:publicFields
class ApplicationConfig {
	var project_path:String;
	var main_path:String;
	var main_route:Array<String>;
	var destination_path:String;
}
