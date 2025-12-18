extends Control

# Cấu hình game
var grid_size = 6
var num_mines = 10
var buttons = []      # Mảng 2 chiều chứa các nút (Button)
var grid_data = []    # Mảng 2 chiều chứa dữ liệu ('*', '0', '1'...)
var game_over = false

# Thêm bảng màu cho các con số (Giống game gốc của Microsoft)
var number_colors = {
	1: Color.BLUE,
	2: Color.GREEN,
	3: Color.RED,
	4: Color.DARK_BLUE,
	5: Color.DARK_RED,
	6: Color.CYAN,
	7: Color.BLACK,
	8: Color.GRAY
}

# Lấy tham chiếu đến GridContainer ta đã tạo ở Bước 1
@onready var grid_container = $VBoxContainer/CenterContainer/PanelContainer/GridContainer

func _ready():
	# Căn giữa bảng chơi
	grid_container.add_theme_constant_override("h_separation", 4)
	grid_container.add_theme_constant_override("v_separation", 4)
	start_game()

func start_game():
	# 1. Xóa các nút cũ (nếu chơi lại)
	for child in grid_container.get_children():
		child.queue_free()
	
	buttons = []
	grid_data = []
	game_over = false
	
	# 2. Tạo dữ liệu bảng trống
	for r in range(grid_size):
		var row_data = []
		var row_btns = []
		for c in range(grid_size):
			row_data.append(0) # 0 nghĩa là ô trống
			
			# Tạo nút bấm giao diện
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(60, 60) # Kích thước nút cho dễ bấm trên đt
			btn.name = str(r) + "_" + str(c)
			
			# KẾT NỐI SỰ KIỆN: Khi bấm nút -> gọi hàm _on_button_pressed
			# .bind(r, c) giúp gửi kèm toạ độ vào hàm
			btn.pressed.connect(_on_button_pressed.bind(r, c))
			
			grid_container.add_child(btn)
			row_btns.append(btn)
		
		grid_data.append(row_data)
		buttons.append(row_btns)

	# 3. Rải mìn và tính số
	generate_mines()
	calculate_numbers()

func generate_mines():
	var count = 0
	while count < num_mines:
		var r = randi() % grid_size
		var c = randi() % grid_size
		if grid_data[r][c] != -1: # Giả sử -1 là mìn
			grid_data[r][c] = -1
			count += 1

func calculate_numbers():
	# Mảng các hướng xung quanh (giống hệt Python)
	var directions = [
		Vector2(-1, -1), Vector2(-1, 0), Vector2(-1, 1),
		Vector2(0, -1),                  Vector2(0, 1),
		Vector2(1, -1),  Vector2(1, 0),  Vector2(1, 1)
	]
	
	for r in range(grid_size):
		for c in range(grid_size):
			if grid_data[r][c] == -1: continue # Nếu là mìn thì bỏ qua
			
			var mines_count = 0
			for d in directions:
				var nr = r + d.x
				var nc = c + d.y
				# Kiểm tra biên
				if nr >= 0 and nr < grid_size and nc >= 0 and nc < grid_size:
					if grid_data[nr][nc] == -1:
						mines_count += 1
			
			grid_data[r][c] = mines_count

func _on_button_pressed(r, c):
	if game_over: return
	
	var btn = buttons[r][c]
	var value = grid_data[r][c]
	
	# Nếu bấm trúng mìn (-1)
	if value == -1:
		btn.text = "💣" # Dùng Emoji quả bom
		btn.modulate = Color.RED # Đổi màu đỏ
		game_over = true
		reveal_all_mines()
		print("Bạn thua rồi!")
		return

	# Nếu bấm trúng ô an toàn
	reveal_cell(r, c)
		
	# Kiểm tra thắng
	if check_win():
		print("Chiến thắng!")
		game_over = true

func reveal_cell(r, c):
	# Kiểm tra biên
	if r < 0 or r >= grid_size or c < 0 or c >= grid_size: return
	
	var btn = buttons[r][c]
	if btn.disabled: return # Đã mở rồi thì thôi
	
	btn.disabled = true # Vô hiệu hoá nút (để biết là đã mở)
	
	# Đổi style của nút đã mở (nền phẳng, màu xám nhạt)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color("d2d2d2ff") # Màu xám nhạt
	style_box.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("disabled", style_box)
	
	var value = grid_data[r][c]
	
	if value > 0:
		btn.text = str(value)
		# Tô đậm chữ
		btn.add_theme_font_size_override("font_size", 24) 
		# Tô màu số theo quy tắc (1 xanh, 2 đỏ...)
		if value in number_colors:
			btn.add_theme_color_override("font_disabled_color", number_colors[value])
	elif value == 0:
		# Nếu là ô số 0 (trống), loang ra xung quanh (Đệ quy)
		btn.text = "" 
		var directions = [
			Vector2(-1, -1), Vector2(-1, 0), Vector2(-1, 1),
			Vector2(0, -1),                  Vector2(0, 1),
			Vector2(1, -1),  Vector2(1, 0),  Vector2(1, 1)
		]
		for d in directions:
			reveal_cell(r + d.x, c + d.y)

func reveal_all_mines():
	for r in range(grid_size):
		for c in range(grid_size):
			if grid_data[r][c] == -1:
				buttons[r][c].text = "💣" # Hiện icon bom
				buttons[r][c].disabled = true

func check_win():
	var opened_count = 0
	for r in range(grid_size):
		for c in range(grid_size):
			if buttons[r][c].disabled:
				opened_count += 1
	return opened_count == (grid_size * grid_size - num_mines)


func _on_btn_reset_pressed() -> void:
	start_game() # Replace with function body.
