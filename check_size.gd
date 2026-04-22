extends SceneTree

func _init():
    var img = Image.new()
    var err = img.load("res://assets/player/improved/s.png")
    var f = FileAccess.open("res://size.txt", FileAccess.WRITE)
    if err == OK:
        f.store_string("size: " + str(img.get_size()))
    else:
        f.store_string("error: " + str(err))
    f.close()
    quit()
