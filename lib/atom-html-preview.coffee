url                   = require 'url'
{CompositeDisposable} = require 'atom'

HtmlPreviewView       = require './atom-code-preview-view'

module.exports =
  config:
    triggerOnSave:
      type: 'boolean'
      description: 'Watch will trigger on save.'
      default: false
    preserveWhiteSpaces:
      type: 'boolean'
      description: 'Enclose data in pre statements.'
      default: false
    fileEndings:
      type: 'array'
      title: 'Preserve File Endings'
      description: 'File endings to enclose in pre statements.'
      default: ["c", "h"]
      items:
        type: 'string'
    enableMathJax:
      type: 'boolean'
      description: 'Enable MathJax inline rendering \\f$ \\omega = \\frac{1}{2 pi} \\f$'
      default: false

  htmlPreviewView: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-code-preview:toggle': => @toggle()

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'html-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        new HtmlPreviewView(editorId: pathname.substring(1))
      else
        new HtmlPreviewView(filePath: pathname)

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    uri = "html-preview://editor/#{editor.id}"

    previewPane = atom.workspace.paneForURI(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForURI(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (htmlPreviewView) ->
      if htmlPreviewView instanceof HtmlPreviewView
        htmlPreviewView.renderHTML()
        previousActivePane.activate()

  deactivate: ->
    @subscriptions.dispose()
