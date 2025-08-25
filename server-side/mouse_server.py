#!/usr/bin/env python3
"""
PC Mouse & Keyboard Control Server for Ubuntu
Receives commands from Flutter mobile app and controls the mouse and keyboard

Requirements:
pip install flask pynput

Run with: python3 mouse_keyboard_server.py
"""

from flask import Flask, request, jsonify
import json
from pynput.mouse import Button, Listener as MouseListener
from pynput import mouse, keyboard
from pynput.keyboard import Key, KeyCode
import threading
import socket
import sys

app = Flask(__name__)

# Controllers
mouse_controller = mouse.Controller()
keyboard_controller = keyboard.Controller()

def get_local_ip():
    """Get the local IP address"""
    try:
        # Connect to a remote server to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return "127.0.0.1"

def get_key_from_string(key_string):
    """Convert string to pynput key"""
    # Special keys mapping
    special_keys = {
        'enter': Key.enter,
        'space': Key.space,
        'backspace': Key.backspace,
        'delete': Key.delete,
        'tab': Key.tab,
        'escape': Key.esc,
        'shift': Key.shift,
        'ctrl': Key.ctrl,
        'alt': Key.alt,
        'cmd': Key.cmd,
        'up': Key.up,
        'down': Key.down,
        'left': Key.left,
        'right': Key.right,
        'home': Key.home,
        'end': Key.end,
        'page_up': Key.page_up,
        'page_down': Key.page_down,
        'caps_lock': Key.caps_lock,
        'f1': Key.f1, 'f2': Key.f2, 'f3': Key.f3, 'f4': Key.f4,
        'f5': Key.f5, 'f6': Key.f6, 'f7': Key.f7, 'f8': Key.f8,
        'f9': Key.f9, 'f10': Key.f10, 'f11': Key.f11, 'f12': Key.f12
    }
    
    key_lower = key_string.lower()
    if key_lower in special_keys:
        return special_keys[key_lower]
    else:
        # Regular character
        return KeyCode.from_char(key_string)

@app.route('/ping', methods=['GET'])
def ping():
    """Health check endpoint"""
    return jsonify({"status": "ok", "message": "Server is running"})

@app.route('/mouse', methods=['POST'])
def handle_mouse_command():
    """Handle mouse commands from mobile app"""
    try:
        data = request.get_json()
        action = data.get('action')
        command_data = data.get('data', {})
        
        if action == 'move':
            # Move mouse cursor
            dx = command_data.get('dx', 0)
            dy = command_data.get('dy', 0)
            
            # Get current position and add delta
            current_x, current_y = mouse_controller.position
            new_x = current_x + dx
            new_y = current_y + dy
            
            mouse_controller.position = (new_x, new_y)
            
        elif action == 'left_click':
            mouse_controller.click(Button.left, 1)
            
        elif action == 'right_click':
            mouse_controller.click(Button.right, 1)
            
        elif action == 'double_click':
            mouse_controller.click(Button.left, 2)
            
        elif action == 'scroll_up':
            mouse_controller.scroll(0, 1)
            
        elif action == 'scroll_down':
            mouse_controller.scroll(0, -1)
            
        elif action == 'drag_start':
            mouse_controller.press(Button.left)
            
        elif action == 'drag_end':
            mouse_controller.release(Button.left)
            
        else:
            return jsonify({"error": "Unknown mouse action"}), 400
            
        return jsonify({"status": "success"})
        
    except Exception as e:
        print(f"Error handling mouse command: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/keyboard', methods=['POST'])
def handle_keyboard_command():
    """Handle keyboard commands from mobile app"""
    try:
        data = request.get_json()
        action = data.get('action')
        command_data = data.get('data', {})
        
        if action == 'type':
            # Type text
            text = command_data.get('text', '')
            keyboard_controller.type(text)
            
        elif action == 'key_press':
            # Press and release a single key
            key_string = command_data.get('key', '')
            key = get_key_from_string(key_string)
            keyboard_controller.press(key)
            keyboard_controller.release(key)
            
        elif action == 'key_combination':
            # Handle key combinations like Ctrl+C, Alt+Tab, etc.
            keys = command_data.get('keys', [])
            if not keys:
                return jsonify({"error": "No keys provided for combination"}), 400
            
            # Convert strings to keys
            key_objects = [get_key_from_string(k) for k in keys]
            
            # Press all keys
            for key in key_objects:
                keyboard_controller.press(key)
            
            # Release all keys in reverse order
            for key in reversed(key_objects):
                keyboard_controller.release(key)
                
        elif action == 'key_hold_start':
            # Start holding a key
            key_string = command_data.get('key', '')
            key = get_key_from_string(key_string)
            keyboard_controller.press(key)
            
        elif action == 'key_hold_end':
            # Stop holding a key
            key_string = command_data.get('key', '')
            key = get_key_from_string(key_string)
            keyboard_controller.release(key)
            
        else:
            return jsonify({"error": "Unknown keyboard action"}), 400
            
        return jsonify({"status": "success"})
        
    except Exception as e:
        print(f"Error handling keyboard command: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/status', methods=['GET'])
def get_status():
    """Get current mouse position and server status"""
    x, y = mouse_controller.position
    return jsonify({
        "status": "running",
        "mouse_position": {"x": x, "y": y},
        "server_ip": get_local_ip(),
        "features": ["mouse", "keyboard"]
    })

def print_server_info():
    """Print server information"""
    local_ip = get_local_ip()
    print("=" * 60)
    print("PC Mouse & Keyboard Control Server Starting...")
    print("=" * 60)
    print(f"Server IP: {local_ip}")
    print(f"Server Port: 8080")
    print(f"Mobile App Connection URL: http://{local_ip}:8080")
    print("=" * 60)
    print("Available Features:")
    print("• Mouse Control (move, click, scroll, drag)")
    print("• Keyboard Control (type, key press, combinations)")
    print("=" * 60)
    print("API Endpoints:")
    print("• POST /mouse - Mouse commands")
    print("• POST /keyboard - Keyboard commands")
    print("• GET /status - Server status")
    print("• GET /ping - Health check")
    print("=" * 60)
    print("Instructions:")
    print("1. Make sure your phone and PC are on the same WiFi network")
    print(f"2. Enter this IP in your mobile app: {local_ip}")
    print("3. Tap 'Connect' in the mobile app")
    print("4. Use your phone as a touchpad and keyboard!")
    print("=" * 60)
    print("Press Ctrl+C to stop the server")
    print("=" * 60)

if __name__ == '__main__':
    print_server_info()
    
    try:
        # Run Flask app
        app.run(
            host='0.0.0.0',  # Allow connections from any IP
            port=8080,
            debug=False,
            threaded=True
        )
    except KeyboardInterrupt:
        print("\nShutting down server...")
        sys.exit(0)
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)