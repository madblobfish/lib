import sublime
import sublime_plugin

class SwitchDictionaryCommand(sublime_plugin.WindowCommand):
    def run(self, dictionary):
        sublime.active_window().active_view().settings().set('dictionary', dictionary)
