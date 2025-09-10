# Copilot Instructions for VIP_FreeVIPGiveaway

## Repository Overview

This repository contains a SourcePawn plugin for SourceMod that implements a **Free VIP Giveaway** system for Source engine game servers. The plugin automatically grants temporary VIP status to active players during specified time periods when minimum player count requirements are met.

### Key Features
- **Time-based VIP events**: Configure start/end timestamps for giveaway periods
- **Player count thresholds**: Require minimum number of active players
- **Automatic VIP management**: Grant/revoke VIP based on activity and spectator status
- **Hostname modification**: Update server name during active giveaway periods
- **Cookie tracking**: Remember which players have received extended VIP
- **Native API**: Expose functions for other plugins to query giveaway status

## Technical Environment

- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11.0+ (currently using 1.11.0-git6934)
- **Build System**: SourceKnight for dependency management and compilation
- **Target Output**: Compiled .smx plugin files
- **Dependencies**:
  - `sourcemod` (core framework)
  - `clientprefs` (cookie system)
  - `cstrike` (CS:GO/CS2 specific functions)
  - `vip_core` (VIP management system)
  - `multicolors` (chat color formatting)

## Repository Structure

```
addons/sourcemod/scripting/
├── VIP_FreeVIPGiveaway.sp          # Main plugin source code (349 lines)
└── include/
    └── VIP_FreeVIPGiveaway.inc     # Native function definitions for other plugins

.github/
├── workflows/ci.yml                # GitHub Actions CI/CD pipeline
├── dependabot.yml                  # Dependency updates configuration
└── copilot-instructions.md         # This file - coding agent instructions

sourceknight.yaml                   # Build configuration and dependencies
.gitignore                          # Excludes build artifacts, .smx files
```

**Generated Files** (not in repository):
- `cfg/sourcemod/VIP_FreeVIPGiveaway.cfg` - Auto-generated ConVar configuration
- `.sourceknight/` - Build cache and output directory

## Build Process

### Using SourceKnight (Recommended)
The repository uses SourceKnight for automated dependency management and building:

```bash
# Install SourceKnight if not already available
pip install sourceknight

# Build the plugin (handles dependency downloads automatically)
sourceknight build

# Output will be in .sourceknight/package/addons/sourcemod/plugins/
```

**Note**: SourceKnight installation may fail on some systems due to dependency issues. The CI/CD pipeline uses Docker containers with SourceKnight pre-installed.

### Manual Build Process
If SourceKnight installation fails, you can build manually:
```bash
# 1. Download dependencies manually:
#    - SourceMod 1.11.0-git6934 from https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-linux.tar.gz
#    - MultiColors include from https://github.com/srcdslab/sm-plugin-MultiColors
#    - VIP Core include from https://github.com/srcdslab/sm-plugin-VIP-Core

# 2. Place include files in addons/sourcemod/scripting/include/
# 3. Compile using SourceMod compiler
spcomp addons/sourcemod/scripting/VIP_FreeVIPGiveaway.sp -o VIP_FreeVIPGiveaway.smx
```

### CI/CD Pipeline
- **Trigger**: Push, pull request, or manual dispatch
- **Build**: Uses maxime1907/action-sourceknight@v1
- **Output**: Creates tar.gz releases with compiled plugins
- **Versioning**: Uses git tags or "latest" for main/master branch

## Code Style & Conventions

### SourcePawn Specific
```sourcepawn
#pragma semicolon 1          // Always used
#pragma newdecls required    // Always used

// Variable naming conventions
ConVar g_Cvar_MinPlayers;    // Global ConVars with g_Cvar_ prefix
char g_sHostname[256];       // Global strings with g_s prefix
Cookie g_hCookie;            // Handles with g_h prefix

// Function naming
public void OnPluginStart()  // SourceMod callbacks in PascalCase
void GiveVIP(int client)     // Custom functions in PascalCase
```

### Formatting Standards
- **Indentation**: Use tabs (4 spaces equivalent)
- **Braces**: Opening brace on same line for functions, new line for control structures
- **Variables**: Use descriptive names, avoid abbreviations
- **Comments**: Document complex logic, avoid obvious comments

## Plugin Architecture

### Core Components

1. **ConVar System** (`OnPluginStart()`):
   - `sm_freevip_min_players`: Minimum players required (0 = always on)
   - `sm_freevip_group`: VIP group to assign
   - `sm_freevip_timestamp_start/end`: Active period timestamps
   - `sm_freevip_hostname_prefix`: Server name prefix during events

2. **Event Handling**:
   - `Event_RoundStart()`: Check conditions and manage VIP assignments
   - `VIP_OnClientLoaded()`: Handle player connections
   - `OnClientDisconnect()`: Clean up temporary VIP on disconnect

3. **VIP Management Functions**:
   - `GiveVIP(client)`: Grant VIP to eligible players
   - `SetVIP(client)`: Extend existing VIP duration
   - `IsFreeVIPOn()`: Check if giveaway is currently active

4. **Native API** (VIP_FreeVIPGiveaway.inc):
   - `FreeVIP_IsFreeVIPOn()`: Query giveaway status
   - `FreeVIP_GetStartTimeStamp()`/`FreeVIP_GetEndTimeStamp()`: Get event timing

### Key Logic Flow

1. **Round Start Check**:
   - Verify current time is within configured start/end timestamps
   - Count active players (excluding spectators and SourceTV)
   - If minimum players met: grant VIP to non-VIP active players
   - If insufficient players: remove temporary VIP from players

2. **Player Connection**:
   - Automatically grant VIP if conditions are met and player doesn't have VIP
   - Extend VIP duration for existing VIP players (tracked via cookies)

3. **Hostname Management**:
   - Add prefix to server hostname during active giveaway periods
   - Only modify if prefix not already present

## Common Development Tasks

### Adding New ConVars
```sourcepawn
// In OnPluginStart()
ConVar g_Cvar_NewSetting = CreateConVar("sm_freevip_newsetting", "default", "Description", FCVAR_NONE);

// Use AutoExecConfig() to generate .cfg file automatically (already called in this plugin)
```

### Modifying VIP Conditions
Key function to modify: `Event_RoundStart()` (lines 105-183)
- Player counting logic (lines 129-137)
- VIP assignment loop (lines 141-159)  
- VIP removal logic (lines 170-176)

### Adding Native Functions
1. Add declaration to `VIP_FreeVIPGiveaway.inc`
2. Register in `AskPluginLoad2()` (lines 69-78)
3. Implement native handler function (see examples: lines 80-93)

### Database Integration (if needed in future)
This plugin currently uses only ConVars and Cookies (client preferences). If database functionality is needed:
- All SQL queries must be asynchronous
- Use prepared statements to prevent SQL injection
- Use transactions for multi-query operations
- Example pattern:
```sourcepawn
Database db = SQL_Connect("database_config");
char query[256];
db.Format(query, sizeof(query), "SELECT * FROM table WHERE id = ?");
db.Query(CallbackFunction, query, clientId);
```

## Testing & Validation

### Local Testing
1. **Build Verification**:
   ```bash
   sourceknight build
   # Verify no compilation errors
   ```

2. **Plugin Testing**:
   - Load on test server with VIP Core plugin
   - Test with different player counts
   - Verify timestamp-based activation/deactivation
   - Test spectator/active player transitions

### Key Test Scenarios
- **Minimum players**: Test below/above threshold behavior
- **Time boundaries**: Test activation at start/end timestamps
- **VIP interactions**: Test with existing VIP players
- **Disconnection**: Verify temporary VIP cleanup
- **Commands**: Test `sm_freevip` status command

## Dependencies & Integration

### Required Plugins
- **VIP Core**: Provides VIP management functions (`VIP_GiveClientVIP`, `VIP_IsClientVIP`, etc.)
- **MultiColors**: Provides colored chat message functions (`CPrintToChatAll`, `CReplyToCommand`)

### Optional Integration
- Other plugins can use the native functions to check giveaway status
- Cookie system allows persistent tracking across player sessions

## Performance Considerations

### Optimization Points
- **Player loops**: Only iterate through connected clients
- **ConVar caching**: Store frequently accessed ConVar values
- **Event frequency**: Round-based checking minimizes performance impact
- **Memory management**: Proper cleanup on disconnect events

### Monitoring
- Use `sm_profiler` command to monitor performance impact
- Watch for excessive loops in frequently called functions
- Monitor cookie usage for memory leaks

## Security & Best Practices

### Input Validation
- Validate client indices before API calls
- Check `IsClientInGame()` and `IsClientAuthorized()` before VIP operations
- Sanitize ConVar inputs where appropriate

### Admin Permissions
- Plugin uses `ADMFLAG_CUSTOM1` for VIP flag management
- Ensure proper permission handling for admin commands

### Error Handling
- Check return values from VIP Core functions
- Handle edge cases (invalid timestamps, missing dependencies)
- Graceful degradation if VIP Core is unavailable

## Troubleshooting

### Common Issues
1. **VIP not granted**: Check timestamp configuration and player count
2. **Compilation errors**: Verify all dependencies are in `scripting/include/`
3. **Runtime errors**: Check SourceMod error logs for missing natives
4. **Cookie issues**: Ensure `clientprefs` extension is loaded

### Debug Strategies
- Use `PrintToServer()` for debugging output
- Check ConVar values with `sm_cvar list freevip`
- Monitor VIP Core status with `sm_vip_status`
- Review plugin load order in case of dependency issues

## Version Management

- Use semantic versioning in plugin info (currently 2.1)
- Update version in both plugin header and git tags
- CI automatically creates releases from tags
- Keep changelog for significant changes

---

This plugin integrates tightly with the VIP Core ecosystem and follows SourceMod best practices. When making changes, always consider the impact on server performance and ensure proper cleanup of resources.