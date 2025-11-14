# F5 iCall using Event Trigger: Traffic Group State Detection and Dynamic BGP Advertisement


## Overview
This repository contains F5 iCall scripts and supporting shell utilities designed to automate BGP-related failover actions between traffic groups on BIG-IP systems. 
The solution monitors BGP session states, dynamically manages route domains, and triggers iCall events to ensure high availability and consistent traffic handling during failover or topology changes.

## Flows and Terminology
Basic flows for iCall configurations start with an event followed by a handler kicking off a script. A more complex example might start with a periodic handler that kicks off a script that generates an event that another handler picks up and generates another script. 
iCall is BIG-IP’s event-based granular automation system that enables comprehensive control over configuration and other system settings and objects.
The main programmability points of entrance for BIG-IP are the data plane, the control plane, and the management plane. My bare bones description of the three: <br>

**Data Plane** - Client/server traffic on the wire and flowing through devices - (iRules) <br>
**Control Plane** - Tactical control of local system resources - (iCall) <br>
**Management Plane** - Strategic control of distributed system resources - (iControl)} <br>

## Components 
The iCall system has three components: <br> 

**events** <br> 
**handlers** <br> 
**scripts** <br> 

At a high level, an event is "the message," some named object that has context (key value pairs), scope (pool, virtual, etc), origin (daemon, iRules), and a timestamp. Events occur when specific, configurable, pre-defined conditions are met. A handler initiates a script and is the decision mechanism for event data. There are three types of handlers:  <br>

**Triggered** - reacts to a specific event  <br>
**Periodic** - reacts to a timer  <br>
**Perpetual** - runs under the control of a daemon  <br>

Finally, there are scripts. Scripts perform the action as a result of event and handler. The scripts are TMSH Tcl scripts organized under the /sys icall section of the system.


This iCall script dynamically adjusts BGP route advertisements based on the **traffic group failover state** of an F5 BIG-IP device.  
When the traffic group is **ACTIVE**, the script updates BGP route metrics to advertise routes with good preference values.  
When the device is **STANDBY**, it suppresses or denies route advertisements to prevent routing conflicts or duplicate announcements. <br>

This solution ensures **high availability** and **intelligent route advertisement** in Active/Standby BIG-IP clusters integrated with BGP. <br>


![](/images/picture1.png)
---


## Triggering Events 

### 1. **user_alert.conf**
Defines system alerts to trigger iCall events based on BGP neighbor state changes or traffic group transitions.

#### Key Alerts:
- **bgp_down_by_event** — Detects BGP neighbor down events.
- **bgp_up_by_event** — Detects BGP neighbor up events.
- **tg1_standby / tg1_active** — Handles failover for `traffic-group-1`.
- **tg2_standby / tg2_active** — Handles failover for `traffic-group-2`.

Each alert executes the appropriate iCall event via the `tmsh generate sys icall event` command.

---

### 2. **bigip_script.conf**
Main iCall script: `/Common/sys_failover_manager`

#### Description:
Responds to system-generated iCall events and executes the appropriate action or script depending on the context (BGP up/down, active/standby state, or traffic group identifier).

#### Supported Actions:
| Action | Traffic Group | Description |
|--------|----------------|-------------|
| `bgp-down` | any | Executes **bgp-check-down.sh** to process BGP peer failures and initiate standby mode. |
| `bgp-up` | any | Executes **bgp-check-up.sh** to reestablish BGP peers after recovery. |
| `standby` | traffic-group-1 | Executes **tg-1-failover.sh** to set AS path prepend for RD1/2. |
| `active` | traffic-group-1 | Executes **bgp-failact.sh 1** to remove prepend and bring up active routes. |
| `standby` | traffic-group-2 | Executes **tg-2-failover.sh** for RD3/4 AS path prepend configuration. |
| `active` | traffic-group-2 | Executes **bgp-failact.sh 2** to restore active route advertisement. |

All actions log events via `tmsh::log` for auditability.

---

### 3. **Shell Scripts**
Located under `/config/monitors/custom/`

#### **fetch-route-domains.sh**
Retrieves route domains associated with BGP configurations and stores them in `/var/tmp/route-domains`.

#### **bgp-check-up.sh**
Monitors BGP neighbors for “Established, up” status and dynamically adjusts AS path prepend settings in `set-prepend.cfg`.

#### **bgp-check-down.sh**
Detects BGP peers in the “down” state, initiates traffic group failover, and applies AS path prepend to reduce route preference.

#### **bgp-check-offline.sh**
Forces the device offline if multiple BGP peers are down to prevent partial routing inconsistencies.

#### **bgp-failact.sh**
Removes AS path prepend entries and resets outbound BGP sessions after a failover recovery.

#### **tg-1-failover.sh / tg-2-failover.sh**
Traffic group–specific scripts to apply AS path prepend on standby devices and ensure correct route advertisement hierarchy.

#### **bring-online.sh**
Monitors CMI sync status and restores the device to online/standby mode if conditions are met.

#### **unset-prepend.cfg**
Configuration file defining route map adjustments used by the failover scripts.

---

## Workflow Summary

1. **BGP Event Detection**
   - `user_alert.conf` monitors syslog for BGP “neighbor down/up” events.
   - On match, it triggers the `sys_failover_manager` iCall event.

2. **iCall Script Execution**
   - The iCall handler (`bigip_script.conf`) identifies the context (`action`, `tgroup`) and runs the matching shell script.

3. **Dynamic Failover**
   - Scripts manage AS path prepending/unsetting to control route advertisement preference.
   - BGP sessions are soft reset using `vtysh` to propagate changes immediately.

4. **Failback Handling**
   - When BGP peers restore connectivity, the prepend configuration is reverted, and normal routing preference resumes.

---

## Deployment Instructions

1. **Copy Scripts**
   ```bash
   mkdir -p /config/monitors/custom/
   cp *.sh *.cfg /config/monitors/custom/
   chmod +x /config/monitors/custom/*.sh
   ```

2. **Load Configuration**
   ```bash
   tmsh load sys config merge file user_alert.conf
   tmsh load sys config merge file bigip_script.conf
   ```

3. **Validate**
   ```bash
   tmsh list sys icall script /Common/sys_failover_manager
   tmsh show sys icall event
   ```

4. **Test Failover**
   - Simulate BGP down/up by disabling a BGP neighbor.
   - Observe logs under `/var/log/ltm` or `/var/log/messages` for iCall and script activity.

---

## Logging & Troubleshooting

- Logs: `/var/log/ltm`, `/var/log/messages`
- Temporary files: `/var/tmp/`
- Route domain file: `/var/tmp/route-domains`
- Verify iCall event context:
  ```bash
  tmsh show sys icall event all-properties
  ```

---

## Version Information

- **BIG-IP Version Tested:** 17.5.1.3
- **Purpose:** Automate BGP failover handling and traffic-group synchronization using F5 iCall and Bash scripting.

---

## License

This project is intended for operational automation within F5 environments.  
Use at your own risk and validate in a test environment prior to production deployment.


## 🧾 References & Resources

- [F5 iCall Overview](https://community.f5.com/kb/technicalarticles/what-is-icall/288206)  
- [iCall Triggers Example](https://community.f5.com/kb/technicalarticles/icall-triggers---invalidating-cache-from-irules/286032)  
- [F5 BGP Peering in Active/Standby Cluster](https://community.f5.com/discussions/technicalforum/f5-bgp-peering-in-active-standby-cluster/343186)  
- [F5 Support Article K10168](https://my.f5.com/manage/s/article/K10168)  
- [iCall Script for Active Member Execution](https://community.f5.com/kb/codeshare/icall-script-that-only-runs-on-active-member/283516)  
- [TMSH get_field_value Reference](https://clouddocs.f5.com/api/tmsh/tmsh__get_field_value.html)

---

## ⚙️ Notes

- Requires F5 BIG-IP with **iCall** and **BGP (imish/ZebOS)** enabled.
- Adjust prefix lists, metrics, and neighbor IPs according to your environment.
- Recommended to test changes in a **non-production** setup before deployment.

---

## 🧑‍💻 Author
**Marlon Frank**  
*Network and Application Security & F5 Automation Engineer*  
