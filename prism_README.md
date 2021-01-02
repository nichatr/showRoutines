### How to add/change a language (Prism)

- Define the language in Prism project.
- Prism folder: **I:\web-ssd\apps\prism\prism-master**
- In folder **.\components** add the language definition, e.g. **prism-rpg.js**.
- Add the language in file **.\gulpfile.js\path.js**.
- Example:

```javascript
	main: [
    ...
		"components/prism-rpg.js",
```

- Rebuild the languages by running:

```javascript
npm run build
```

- The two files will be rebuilt:
  - **.\themes\prism.css**
  - **.\prism.js**
- copy the two files in \*\*.\showRoutines\*\*
