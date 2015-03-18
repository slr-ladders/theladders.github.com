---
layout: post
title: "MMR is not Measles, Mumps, and Rubella"
date: 2015-01-22 15:58
comments: true
categories: DevOps Monitoring OSS
published: true
---

{% blockquote --Led Zeppelin %}
Communication Breakdown, It's always the same,
I'm having a nervous breakdown, Drive me insane!
{% endblockquote %}

tl;dr -- Use this [plugin](http://github.com/TheLadders/monitor-ds-replication) to monitor 389 Directory Server replication

We've been bitten in the past when the multi-master replication between our authentication servers stops functioning properly and we don't find out about it immediately.  This usually manifests itself as users complaining that they're intermittently unable to authenticate against certain services, which results in a bunch of troubleshooting effort only to discover that the real problem is the user not existing on all IPA servers.

We use [freeIPA](http://freeipa.org) internally as our centralized user management system.  freeIPA combines several standard open source components to provide an "integrated security information management solution".  These components include [389 Directory Server](http://directory.fedoraproject.org/), [MIT Kerberos](http://k5wiki.kerberos.org/wiki/Main_Page), [NTP](http://www.ntp.org), [DNS](http://fedorahosted.org/bind-dyndb-ldap/), [Dogtag certificate system](http://pki.fedoraproject.org/), [SSSD](http://fedorahosted.org/sssd/) as well as several others.  In the absence of custom configuration, freeIPA utilizes two instances of 389 Directory Server - one for traditional directory information on the standard port 389, and one for [PKI/CA](http://en.wikipedia.org/wiki/Public_key_infrastructure) on port 7389.  389 Directory Server's multi-master replication (MMR) support ensures that directory and certificate data is available from any node in the cluster.

To prevent this unfortunate scenario in the future, we developed a simple [nagios](http://www.nagios.org)/[icinga](http://www.icinga.org) plugin to assess replication health within the 389 Directory Server cluster.  Fortunately, information including structure of the cluster and status of replication is stored within the LDAP schema itself.  In developing the plugin, we hoped to avoid storing any authentication details in the plugin or the nagios/icinga configuration.  This required enabling anonymous read-only querying of the replication agreement data.  Daniel James Scott's [blog post](http://danieljamesscott.org/11-articles/application-guides/26-freeipa-replication-monitoring.html) provided very clear instructions for enabling anonymous read/search/compare access to the replication agreements.  Our [plugin](http://github.com/TheLadders/monitor-ds-replication) uses the [Net::LDAP](http://rubygems.org/gems/net-ldap) Ruby gem to interact with a 389 Directory Server instance to discover all of the downstream replicas and their respective status.  We query the ldap server with base ```cn=config``` and filter on ```(objectclass=nsds5replicationagreement)```.  The equivalent command line query is:
```
ldapsearch -x -h openldap_server.example.com -b cn=config '(objectclass=nsds5replicationagreement)'
```
This yields data similar to:

```
# extended LDIF
#
# LDAPv3
# base <cn=config> with scope subtree
# filter: (objectclass=nsds5replicationagreement)
# requesting: ALL
#

# meToipa-1.example.com, replica, dc\3Dexample\2Cdc\3com, mapping tree, config
dn: cn=meToipa-1.example.com,cn=replica,cn=dc\3Dexample\2Cdc\3Dcom,cn=mapping tree,cn=config
cn: meToipa-1.example.com
objectClass: nsds5replicationagreement
objectClass: top
nsDS5ReplicaTransportInfo: LDAP
description: me to ipa-1.example.com
nsDS5ReplicaRoot: dc=example,dc=com
nsDS5ReplicaHost: ipa-1.example.com
nsds5replicaTimeout: 120
nsDS5ReplicaPort: 389
nsDS5ReplicatedAttributeList: (objectclass=*) $ EXCLUDE memberof idnssoaserialentryusn krblastsuccessfulauth krblastfailedauth krbloginfailedcount
nsDS5ReplicaBindMethod: SASL/GSSAPI
nsDS5ReplicatedAttributeListTotal: (objectclass=*) $ EXCLUDE entryusn krblastsuccessfulauth krblastfailedauth krbloginfailedcount
nsds5replicareapactive: 0
nsds5replicaLastUpdateStart: 20150121214458Z
nsds5replicaLastUpdateEnd: 20150121214501Z
nsds5replicaChangesSentSinceStartup:: MTM6MjAwMzUxNy8wIDY6NC8wIDE0OjQ0MjkvMCA=
nsds5replicaLastUpdateStatus: 1 Can't acquire busy replica
nsds5replicaUpdateInProgress: FALSE
nsds5replicaLastInitStart: 0
nsds5replicaLastInitEnd: 0

# meToipa-2.example.com, replica, dc\3Dexample\2Cdc\3Dcom, mapping tree, config
dn: cn=meToipa-2.example.com,cn=replica,cn=dc\3Dexample\2Cdc\3Dcom,cn=mapping tree,cn=config
cn: meToipa-2.example.com
objectClass: nsds5replicationagreement
objectClass: top
nsDS5ReplicaTransportInfo: LDAP
description: me to ipa-2.example.com
nsDS5ReplicaRoot: dc=example,dc=com
nsDS5ReplicaHost: ipa-2.example.com
nsds5replicaTimeout: 120
nsDS5ReplicaPort: 389
nsDS5ReplicatedAttributeList: (objectclass=*) $ EXCLUDE memberof idnssoaserialentryusn krblastsuccessfulauth krblastfailedauth krbloginfailedcount
nsDS5ReplicaBindMethod: SASL/GSSAPI
nsDS5ReplicatedAttributeListTotal: (objectclass=*) $ EXCLUDE entryusn krblastsuccessfulauth krblastfailedauth krbloginfailedcount
nsds5replicareapactive: 0
nsds5replicaLastUpdateStart: 20150121214628Z
nsds5replicaLastUpdateEnd: 0
nsds5replicaChangesSentSinceStartup:: Njo0MzEyLzAgMTM6NDAzMjMzOS8wIA==
nsds5replicaLastUpdateStatus: 0 Replica acquired successfully: Incremental update started
nsds5replicaUpdateInProgress: TRUE
nsds5replicaLastInitStart: 20141215154802Z
nsds5replicaLastInitEnd: 20141215154807Z
nsds5replicaLastInitStatus: 0 Total update succeeded

# search result
search: 2
result: 0 Success

# numResponses: 3
# numEntries: 2
```

We're primarily concerned with how far in the past each replica successfully performed an update.  As you can see from the output above, the replication agreement with ipa-2.example.com is in the middle of an incremental update and shows a last update end of ```0```.  This does not necessarily mean that replication is broken.  For better or worse, when the server begins an update, it clears the last end time.  To avoid constantly alerting when we're unable to retrieve meaningful replication data, the plugin maintains a state file that tracks the last valid update completion time and how many times a check has resulted in a last update completion of ```0```.  The number of successive zero responses and acceptable number of minutes since last successful update completion are configurable parameters with the ability to set distinct warning and critical thresholds.

Since putting this monitoring in place, we've moved to newer freeIPA servers using replication to seamlessly migrate data from the old servers to the new.  This plugin has already served to identify a breakdown in our replication that was easily remedied because the nodes had not yet significantly diverged.  Other aspects of the health and performance of the IPA cluster are available via SNMP.
