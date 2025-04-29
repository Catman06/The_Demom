extends AudioStreamPlayer

var poly_stream: AudioStreamPlaybackPolyphonic

# Starts self and sets polystream to the playback_stream
func _ready() -> void:
	self.play()
	poly_stream = self.get_stream_playback()

func _on_play_sound(new_stream:AudioStream) -> void:
	poly_stream.play_stream(new_stream)
