# Displaying live speech with Elm

All of the Elm code lives in `Main.elm`. It connects to a Phoenix server using channels, waiting for new sentences to come.


## Build Instructions

Run the following command from the root of this project:

```bash
elm-make Main.elm --output elm.js
```

Or if your are using elm-live:

```bash
elm-live Main.elm --output elm.js
```

Then open `index.html` in your browser!
