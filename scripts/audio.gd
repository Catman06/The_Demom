extends AudioStreamPlayer

var poly_stream: AudioStreamPlaybackPolyphonic

# Starts self and sets polystream to the playback_stream
func _ready() -> void:
	self.play()
	poly_stream = self.get_stream_playback()

func _on_play_sound(path:String) -> void:
	var new_stream = AudioStreamWAV.load_from_file(path)
	print_debug("Playing file: %s" % path)
	poly_stream.play_stream(new_stream)
