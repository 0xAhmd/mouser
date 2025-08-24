#!/usr/bin/env python3
"""
PC Mouse Control Server for Ubuntu
Receives commands from Flutter mobile app and controls the mouse

Requirements:
pip install flask pynput

Run with: python3 mouse_server.py
"""

from flask import Flask, request, jsonify
import json
from pynput.mouse import Button, Listener as MouseListener
from pynput import mouse
import threading
import socket
import sys

app = Flask(__name__)

# Mouse controller
mouse_controller = mouse.Controller()

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
            return jsonify({"error": "Unknown action"}), 400
            
        return jsonify({"status": "success"})
        
    except Exception as e:
        print(f"Error handling mouse command: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/status', methods=['GET'])
def get_status():
    """Get current mouse position and server status"""
    x, y = mouse_controller.position
    return jsonify({
        "status": "running",
        "mouse_position": {"x": x, "y": y},
        "server_ip": get_local_ip()
    })

def print_server_info():
    """Print server information"""
    local_ip = get_local_ip()
    print("=" * 50)
    print("PC Mouse Control Server Starting...")
    print("=" * 50)
    print(f"Server IP: {local_ip}")
    print(f"Server Port: 8080")
    print(f"Mobile App Connection URL: http://{local_ip}:8080")
    print("=" * 50)
    print("Instructions:")
    print("1. Make sure your phone and PC are on the same WiFi network")
    print(f"2. Enter this IP in your mobile app: {local_ip}")
    print("3. Tap 'Connect' in the mobile app")
    print("4. Use your phone as a touchpad!")
    print("=" * 50)
    print("Press Ctrl+C to stop the server")
    print("=" * 50)

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
