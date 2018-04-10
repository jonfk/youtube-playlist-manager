
.PHONY: package-elm clean deep-clean dependencies

package: dependencies temp_build/main.js src/main/main-interop.js src/popup/popup-interop.js
	mkdir -p build/main build/popup
	cp temp_build/main.js build/main/main.js

	cp src/main/main-interop.js build/main/main-interop.js
	cp src/main/main.html build/main/

	cp src/popup/popup-interop.js build/popup/
	cp src/popup/popup.html build/popup/

	cp style/style.css build/
	cp config/manifest.json build/
	@echo successfully packaged elm generated files and js files

temp_build/main.js: src/Main/Main.elm
	elm-make src/Main/Main.elm --output temp_build/main.js

temp_build/youtube/playlist.js: src/Youtube/Playlist.elm
	elm-make src/Youtube/Playlist.elm --output temp_build/youtube/playlist.js

clean:
	rm -rf temp_build
	rm -rf build

deep-clean: clean
	rm -rf elm-stuff
	rm -rf node_modules

dependencies: node_modules/pouchdb/dist/pouchdb.min.js build/pouchdb.min.js build/pouchdb.quick-search.min.js build/pouchdb.find.js

# PouchDB
node_modules/pouchdb/dist/pouchdb.min.js:
	npm install

build/pouchdb.min.js: node_modules/pouchdb/dist/pouchdb.min.js
	mkdir -p build/
	cp node_modules/pouchdb/dist/pouchdb.min.js build/

build/pouchdb.quick-search.min.js:
	mkdir -p build/
	cp node_modules/pouchdb-quick-search/dist/pouchdb.quick-search.min.js build/

build/pouchdb.find.js:
	mkdir -p build/
	cp node_modules/pouchdb/dist/pouchdb.find.js build/pouchdb.find.js

.PHONY: tools
tools: tools/compiler-20170626.tar.gz

# closure compiler tools
tools/compiler-20170626.tar.gz:
	wget http://dl.google.com/closure-compiler/compiler-20170626.tar.gz -O tools/compiler-20170626.tar.gz
	tar xf tools/compiler-20170626.tar.gz -C tools
