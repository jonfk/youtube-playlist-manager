
.PHONY: package-elm clean deep-clean

package: target/main.js src/main/main-interop.js src/popup/popup-interop.js
	mkdir -p build/main build/popup
	cp target/main.js build/main/main.js

	cp src/main/main-interop.js build/main/
	cp src/main/main.html build/main/

	cp src/popup/popup-interop.js build/popup/
	cp src/popup/popup.html build/popup/

	cp style/style.css build/
	cp config/manifest.json build/
	@echo successfully packaged elm generated files and js files

target/main.js: src/Main/Main.elm
	elm-make src/Main/Main.elm --output target/main.js

target/youtube/playlist.js: src/Youtube/Playlist.elm
	elm-make src/Youtube/Playlist.elm --output target/youtube/playlist.js

clean:
	rm -rf target build/main/main.js
	rm -rf build

deep-clean: clean
	rm -rf elm-stuff
