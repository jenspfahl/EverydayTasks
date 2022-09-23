# Help to translate Everyday Tasks !

Please help to translate the app to other languages! You only need a Github-account. 

# These languages are still supported:

* English
* German

# Add a new language

1. Open the reference translation file for English [en.json](https://raw.githubusercontent.com/jenspfahl/EverydayTasks/master/assets/i18n/en.json).
2. Tanslate the values of the file like this: 
```
"button_save": "Save"
```
`"button_save"` remains like it is but `"Save"` should be changed to your language, e.g. `"Speichern"` vor German.
```
"button_save": "Speichern"
```

If you see placeholders surounded with `{}`, just leave the content of this like it is. Example:
```
"task_started_at": "'{title}' started at {when}"
```
Here don't translate `title` and `when` but replace the rest!
```
"task_started_at": "'{title}' gestartet um {when}"
```
 
3. Create a new issue [here](https://github.com/jenspfahl/everydaytasks/issues/new). (Github account needed)
4. Insert your complete tanslation in the description field and write the language name in the title and submit it.
5. I will integrate the translation in the next release.