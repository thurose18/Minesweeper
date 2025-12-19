extends Control

# Cấu hình game
var grid_size = 6
var num_mines = 10
var buttons = []      # Mảng 2 chiều chứa các nút (Button)
var grid_data = []    # Mảng 2 chiều chứa dữ liệu ('*', '0', '1'...)
var game_over = false
var is_flag_mode = false

@onready var long_press_timer = $Timer # Đường dẫn đến Timer bạn vừa tạo
# Biến lưu trạng thái nhấn giữ
var current_r = -1
var current_c = -1
var is_long_press_handled = false # Biến để kiểm tra xem đã cắm cờ chưa

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
			# Không dùng 'pressed' nữa, dùng 'button_down' và 'button_up'
			# 1. Khi ngón tay chạm vào màn hình
			btn.button_down.connect(_on_btn_down.bind(r, c))
		
			# 2. Khi ngón tay nhấc khỏi màn hình
			btn.button_up.connect(_on_btn_up.bind(r, c))
			
			grid_container.add_child(btn)
			row_btns.append(btn)
		
		grid_data.append(row_data)
		buttons.append(row_btns)

	# 3. Rải mìn và tính số
	generate_mines()
	calculate_numbers()
	
# 1. Khi bắt đầu chạm vào nút
func _on_btn_down(r, c):
	if game_over: return
	var btn = buttons[r][c]
	if btn.disabled and btn.text != "🚩": return # Nếu đã mở rồi thì thôi

	# Lưu lại toạ độ nút đang bấm
	current_r = r
	current_c = c
	is_long_press_handled = false 
	
	# Bắt đầu đếm giờ
	long_press_timer.start()
	
# 2. Khi Timer đếm xong (Tức là đã giữ đủ 0.5s) -> CẮM CỜ
func _on_timer_timeout():
	# Nếu ngón tay vẫn chưa nhấc lên
	if current_r != -1:
		is_long_press_handled = true # Đánh dấu là đã xử lý cắm cờ
		
		# Gọi hàm cắm cờ (Logic cũ của bạn)
		toggle_flag(current_r, current_c)
		
		# Rung nhẹ điện thoại để báo hiệu (Chỉ chạy trên đt thật)
		Input.vibrate_handheld(50)
		
# 3. Khi nhấc ngón tay lên
func _on_btn_up(r, c):
	# Dừng đồng hồ ngay lập tức
	long_press_timer.stop()
	
	# Reset biến theo dõi
	current_r = -1
	current_c = -1
	
	# Nếu lúc nãy Timer đã chạy xong và Cắm cờ rồi -> Thì thôi, không đào nữa
	if is_long_press_handled:
		return
	
	# Nếu Timer chưa kịp chạy xong -> Nghĩa là bấm nhanh -> ĐÀO
	dig_cell(r, c)
	
# --- TÁCH LOGIC CŨ RA THÀNH HÀM RIÊNG CHO GỌN ---

func toggle_flag(r, c):
	var btn = buttons[r][c]
	if btn.disabled and btn.text != "🚩": return
	
	if btn.text == "🚩":
		btn.text = "" # Gỡ cờ
		btn.disabled = false
	else:
		btn.text = "🚩" # Cắm cờ
		# btn.disabled = true # (Tuỳ chọn: có thể disable hoặc không)
		
func dig_cell(r, c):
	var btn = buttons[r][c]
	
	# Nếu đang có cờ thì không cho đào
	if btn.text == "🚩": return
	
	var value = grid_data[r][c]
	
	if value == -1:
		# ... Xử lý thua (copy code cũ vào đây) ...
		btn.text = "💣"
		btn.modulate = Color.RED
		game_over = true
		reveal_all_mines()
		print("Bùm!")
	else:
		reveal_cell(r, c)
		if check_win():
			print("Thắng!")
			game_over = true

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
	
	# --- LOGIC CẮM CỜ (MỚI) ---
	if is_flag_mode:
		# Nếu ô đã mở rồi thì không cắm cờ được
		if btn.disabled and btn.text != "🚩": return
		
		if btn.text == "🚩":
			# Nếu đang có cờ -> Gỡ cờ
			btn.text = ""
			btn.disabled = false # Cho phép bấm lại
		else:
			# Nếu chưa có cờ -> Cắm cờ
			btn.text = "🚩"
			# Không disable nút, nhưng ta dùng text để chặn việc đào
		return # Dừng hàm, không thực hiện việc đào bên dưới
		
	# --- LOGIC ĐÀO (CŨ - Có thêm kiểm tra cờ) ---
	# Nếu ô đang có cờ thì không cho đào (để bảo vệ người chơi)
	if btn.text == "🚩": return
	
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
	if btn.text == "🚩": return # GẶP CỜ THÌ KHÔNG TỰ ĐỘNG MỞ
	
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
	start_game() 


func _on_btn_mode_toggled(toggled_on: bool) -> void:
	is_flag_mode = toggled_on
	var btn_mode = $VBoxContainer/HBoxContainer/BtnMode # Đường dẫn đến nút
	
	if is_flag_mode:
		btn_mode.text = "🚩" # Đổi icon thành Cờ
	else:
		btn_mode.text = "⛏️" # Đổi icon thành Xẻng 

pass # Replace with function body.
