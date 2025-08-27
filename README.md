# Cloaxy's 911 Emergency Response System
a standalone 911 system for FiveM servers with no framework dependencies needed.

## Features

### Core Functionality
- `/911 [reason]` - Submit emergency calls
- `/cancel911` - Cancel active emergency calls
- `/respond [id]` - Claim emergency calls (responders only)
- `/clearcall [id]` - Remove calls (admins only)

### Advanced Features
- **Priority System**: Automatic priority assignment (Low, Medium, High)
- **Call Types**: Police, EMS, Fire, Civilian with unique blip colors
- **Real-time Blips**: Dynamic location tracking with auto-updates
- **Distance & ETA**: Automatic calculation for responders
- **Anti-Spam Protection**: Configurable cooldown system
- **Responder Permissions**: Role-based access control
- **JSON Logging**: Complete call history tracking


## Installation

1. Download and extract the `cloaxy-911` folder to your server's `resources` directory
2. Add `ensure cloaxy-911` to your `server.cfg`
3. Configure permissions in `config.lua`
4. Restart your server

## Configuration

Edit `config.lua` to customize:
- Call cooldown times
- Permission groups
- Blip colors and sprites
- UI settings
- Feature toggles

## ACE Permissions Setup

**IMPORTANT:** The permission system has been fixed. Add these permissions to your `server.cfg`:

```
# Police permissions
add_ace group.police 911.police allow
add_ace group.sheriff 911.sheriff allow
add_ace group.state 911.state allow

# EMS permissions
add_ace group.ems 911.ems allow
add_ace group.paramedic 911.paramedic allow
add_ace group.doctor 911.doctor allow

# Fire permissions
add_ace group.fire 911.fire allow
add_ace group.firefighter 911.firefighter allow

# Admin permissions (can access all features)
add_ace group.admin 911.admin allow
add_ace group.moderator 911.moderator allow
add_ace group.staff 911.staff allow
```

### Alternative: Grant all 911 permissions to a group
```
# Give all 911 permissions to admin group
add_ace group.admin 911.* allow

# Or give specific role all their permissions
add_ace group.police 911.police allow
add_ace group.police 911.sheriff allow
add_ace group.police 911.state allow
```

### Testing Permissions
To test if permissions are working:
1. Join the server
2. If you get "not authorized" message, check your ACE permissions
3. Make sure you're in the correct group: `add_principal identifier.steam:YOUR_STEAM_ID group.admin`

## Performance

- Optimized for 0.01ms idle performance
- Lightweight NUI interface
- Efficient blip management
- Minimal server resource usage

---

**Version**: 1.0.0  
**Author**: Cloaxy