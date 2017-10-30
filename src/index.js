'use strict'

require('./css/index.scss')

const Tesseract = require('tesseract.js')

const Elm = require('./Main.elm')
const mountNode = document.getElementById('main')

const app = Elm.Main.embed(mountNode)

app.ports.parseText.subscribe(id => {
  const fileInput = document.getElementById(id)
  const file = fileInput.files[0]
  Tesseract.recognize(file)
    .progress(progress => {
      app.ports.progress.send(progress)
    })
    .then(resp => {
      app.ports.progress.send(null)
      console.log(resp)
      app.ports.receiveText.send(resp)
    })
})
