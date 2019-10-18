module Windows
  class SID
    def self.well_known?(input)
      match = lambda{|x,y,z, match| Regexp.new(x.to_s.gsub(y, z)).match?(match)}
      input = input.upcase

      sid = exact_match = [input, WELL_KNOWN_SIDS[input.to_sym]] if WELL_KNOWN_SIDS.has_key?(input.to_sym)
      sid ||= WELL_KNOWN_SIDS.select{|k,v| /\</ =~ k.to_s}.detect{|k,v| match[k, /\<[^>]+\>/, '\d+-\d+-\d+', input]}
      sid ||= WELL_KNOWN_SIDS.select{|k,v| /x|y/ =~ k.to_s}.detect{|k,v| match[k, /x|y/, '\d+', input]}
    end

    WELL_KNOWN_SIDS = {
      "S-1-0-0": {constant: "NULL", desc: "No Security principal."},
      "S-1-1-0": {constant: "EVERYONE", desc: "A group that includes all users."},
      "S-1-2-0": {constant: "LOCAL", desc: "A group that includes all users who have logged on locally."},
      "S-1-2-1": {constant: "CONSOLE_LOGON", desc: "A group that includes users who are logged on to the physical console. This SID can be used to implement security policies that grant different rights based on whether a user has been granted physical access to the console."},
      "S-1-3-0": {constant: "CREATOR_OWNER", desc: "A placeholder in an inheritable access control entry (ACE). When the ACE is inherited, the system replaces this SID with the SID for the object's creator."},
      "S-1-3-1": {constant: "CREATOR_GROUP", desc: "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the primary group of the object's creator."},
      "S-1-3-2": {constant: "OWNER_SERVER", desc: "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's owner server."},
      "S-1-3-3": {constant: "GROUP_SERVER", desc: "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's group server."},
      "S-1-3-4": {constant: "OWNER_RIGHTS", desc: "A group that represents the current owner of the object. When an ACE that carries this SID is applied to an object, the system ignores the implicit READ_CONTROL and WRITE_DAC permissions for the object owner."},
      "S-1-5": {constant: "NT_AUTHORITY", desc: "A SID containing only the SECURITY_NT_AUTHORITY identifier authority."},
      "S-1-5-1": {constant: "DIALUP", desc: "A group that includes all users who have logged on through a dial-up connection."},
      "S-1-5-2": {constant: "NETWORK", desc: "A group that includes all users who have logged on through a network connection."},
      "S-1-5-3": {constant: "BATCH", desc: "A group that includes all users who have logged on through a batch queue facility."},
      "S-1-5-4": {constant: "INTERACTIVE", desc: "A group that includes all users who have logged on interactively."},
      "S-1-5-5-x-y": {constant: "LOGON_ID", desc: "A logon session. The X and Y values for these SIDs are different for each logon session and are recycled when the operating system is restarted."},
      "S-1-5-6": {constant: "SERVICE", desc: "A group that includes all security principals that have logged on as a service."},
      "S-1-5-7": {constant: "ANONYMOUS", desc: "A group that represents an anonymous logon."},
      "S-1-5-8": {constant: "PROXY", desc: "Identifies a SECURITY_NT_AUTHORITY Proxy."},
      "S-1-5-9": {constant: "ENTERPRISE_DOMAIN_CONTROLLERS", desc: "A group that includes all domain controllers in a forest that uses an Active Directory directory service."},
      "S-1-5-10": {constant: "PRINCIPAL_SELF", desc: "A placeholder in an inheritable ACE on an account object or group object in Active Directory. When the ACE is inherited, the system replaces this SID with the SID for the security principal that holds the account."},
      "S-1-5-11": {constant: "AUTHENTICATED_USERS", desc: "A group that includes all users whose identities were authenticated when they logged on."},
      "S-1-5-12": {constant: "RESTRICTED_CODE", desc: "This SID is used to control access by untrusted code. ACL validation against tokens with RC consists of two checks, one against the token's normal list of SIDs and one against a second list (typically containing RC - the \"RESTRICTED_CODE\" token - and a subset of the original token SIDs). Access is granted only if a token passes both tests. Any ACL that specifies RC must also specify WD - the \"EVERYONE\" token. When RC is paired with WD in an ACL, a superset of \"EVERYONE\", including untrusted code, is described."},
      "S-1-5-13": {constant: "TERMINAL_SERVER_USER", desc: "A group that includes all users who have logged on to a Terminal Services server."},
      "S-1-5-14": {constant: "REMOTE_INTERACTIVE_LOGON", desc: "A group that includes all users who have logged on through a terminal services logon."},
      "S-1-5-15": {constant: "THIS_ORGANIZATION", desc: "A group that includes all users from the same organization. If this SID is present, the OTHER_ORGANIZATION SID MUST NOT be present."},
      "S-1-5-17": {constant: "IUSR", desc: "An account that is used by the default Internet Information Services (IIS) user."},
      "S-1-5-18": {constant: "LOCAL_SYSTEM", desc: "An account that is used by the operating system."},
      "S-1-5-19": {constant: "LOCAL_SERVICE", desc: "A local service account."},
      "S-1-5-20": {constant: "NETWORK_SERVICE", desc: "A network service account."},
      "S-1-5-21-<root domain>-498": {constant: "ENTERPRISE_READONLY_DOMAIN_CONTROLLERS", desc: "A universal group containing all read-only domain controllers in a forest."},
      "S-1-5-21-0-0-0-496": {constant: "COMPOUNDED_AUTHENTICATION", desc: "Device identity is included in the Kerberos service ticket. If a forest boundary was crossed, then claims transformation occurred."},
      "S-1-5-21-0-0-0-497": {constant: "CLAIMS_VALID", desc: "Claims were queried for in the account's domain, and if a forest boundary was crossed, then claims transformation occurred."},
      "S-1-5-21-<machine>-500": {constant: "ADMINISTRATOR", desc: "A user account for the system administrator. By default, it is the only user account that is given full control over the system."},
      "S-1-5-21-<machine>-501": {constant: "GUEST", desc: "A user account for people who do not have individual accounts. This user account does not require a password. By default, the Guest account is disabled."},
      "S-1-5-21-<domain>-502": {constant: "KRBTG", desc: "A service account that is used by the Key Distribution Center (KDC) service."},
      "S-1-5-21-<domain>-512": {constant: "DOMAIN_ADMINS", desc: "A global group whose members are authorized to administer the domain. By default, the DOMAIN_ADMINS group is a member of the Administrators group on all computers that have joined a domain, including the domain controllers. DOMAIN_ADMINS is the default owner of any object that is created by any member of the group."},
      "S-1-5-21-<domain>-513": {constant: "DOMAIN_USERS", desc: "A global group that includes all user accounts in a domain."},
      "S-1-5-21-<domain>-514": {constant: "DOMAIN_GUESTS", desc: "A global group that has only one member, which is the built-in Guest account of the domain."},
      "S-1-5-21-<domain>-515": {constant: "DOMAIN_COMPUTERS", desc: "A global group that includes all clients and servers that have joined the domain."},
      "S-1-5-21-<domain>-516": {constant: "DOMAIN_DOMAIN_CONTROLLERS", desc: "A global group that includes all domain controllers in the domain."},
      "S-1-5-21-<domain>-517": {constant: "CERT_PUBLISHERS", desc: "A global group that includes all computers that are running an enterprise certification authority. Cert Publishers are authorized to publish certificates for User objects in Active Directory."},
      "S-1-5-21-<root-domain>-518": {constant: "SCHEMA_ADMINISTRATORS", desc: "A universal group in a native-mode domain, or a global group in a mixed-mode domain. The group is authorized to make schema changes in Active Directory."},
      "S-1-5-21-<root-domain>-519": {constant: "ENTERPRISE_ADMINS", desc: "A universal group in a native-mode domain, or a global group in a mixed-mode domain. The group is authorized to make forestwide changes in Active Directory, such as adding child domains."},
      "S-1-5-21-<domain>-520": {constant: "GROUP_POLICY_CREATOR_OWNERS", desc: "A global group that is authorized to create new Group Policy Objects in Active Directory."},
      "S-1-5-21-<domain>-521": {constant: "READONLY_DOMAIN_CONTROLLERS", desc: "A global group that includes all read-only domain controllers."},
      "S-1-5-21-<domain>-522": {constant: "CLONEABLE_CONTROLLERS", desc: "A global group that includes all domain controllers in the domain that can be cloned."},
      "S-1-5-21-<domain>-525": {constant: "PROTECTED_USERS", desc: "A global group that is afforded additional protections against authentication security threats. For more information, see [MS-APDS] and [MS-KILE]."},
      "S-1-5-21-<domain>-526": {constant: "KEY_ADMINS", desc: "A security group for delegated write access on the msdsKeyCredentialLink attribute only. The group is intended for use in scenarios where trusted external authorities (for example, Active Directory Federated Services) are responsible for modifying this attribute. Only trusted administrators should be made a member of this group."},
      "S-1-5-21-<domain>-527": {constant: "ENTERPRISE_KEY_ADMINS", desc: "A security group for delegated write access on the msdsKeyCredentialLink attribute only. The group is intended for use in scenarios where trusted external authorities (for example, Active Directory Federated Services) are responsible for modifying this attribute. Only trusted enterprise administrators should be made a member of this group."},
      "S-1-5-21-<domain>-553": {constant: "RAS_SERVERS", desc: "A domain local group for Remote Access Services (RAS) servers. By default, this group has no members. Servers in this group have Read Account Restrictions and Read Logon Information access to User objects in the Active Directory domain local group."},
      "S-1-5-21-<domain>-571": {constant: "ALLOWED_RODC_PASSWORD_REPLICATION_GROUP", desc: "Members in this group can have their passwords replicated to all read-only domain controllers in the domain."},
      "S-1-5-21-<domain>-572": {constant: "DENIED_RODC_PASSWORD_REPLICATION_GROUP", desc: "Members in this group cannot have their passwords replicated to all read-only domain controllers in the domain."},
      "S-1-5-32-544": {constant: "BUILTIN_ADMINISTRATORS", desc: "A built-in group. After the initial installation of the operating system, the only member of the group is the Administrator account. When a computer joins a domain, the Domain Administrators group is added to the Administrators group. When a server becomes a domain controller, the Enterprise Administrators group also is added to the Administrators group."},
      "S-1-5-32-545": {constant: "BUILTIN_USERS", desc: "A built-in group. After the initial installation of the operating system, the only member is the Authenticated Users group. When a computer joins a domain, the Domain Users group is added to the Users group on the computer."},
      "S-1-5-32-546": {constant: "BUILTIN_GUESTS", desc: "A built-in group. The Guests group allows users to log on with limited privileges to a computer's built-in Guest account."},
      "S-1-5-32-547": {constant: "POWER_USERS", desc: "A built-in group. Power users can perform the following actions:\n\tCreate local users and groups.\n\tModify and delete accounts that they have created.\n\tRemove users from the Power Users, Users, and Guests groups.\n\tInstall programs.\n\tCreate, manage, and delete local printers.\n\tCreate and delete file shares."},
      "S-1-5-32-548": {constant: "ACCOUNT_OPERATORS", desc: "A built-in group that exists only on domain controllers. Account Operators have permission to create, modify, and delete accounts for users, groups, and computers in all containers and organizational units of Active Directory except the Built-in container and the Domain Controllers OU. Account Operators do not have permission to modify the Administrators and Domain Administrators groups, nor do they have permission to modify the accounts for members of those groups."},
      "S-1-5-32-549": {constant: "SERVER_OPERATORS", desc: "A built-in group that exists only on domain controllers. Server Operators can perform the following actions:\n\tLog on to a server interactively.\n\tCreate and delete network shares.\n\tStart and stop services.\n\tBack up and restore files.\n\tFormat the hard disk of a computer.\n\tShut down the computer."},
      "S-1-5-32-550": {constant: "PRINTER_OPERATORS", desc: "A built-in group that exists only on domain controllers. Print Operators can manage printers and document queues."},
      "S-1-5-32-551": {constant: "BACKUP_OPERATORS", desc: "A built-in group. Backup Operators can back up and restore all files on a computer, regardless of the permissions that protect those files."},
      "S-1-5-32-552": {constant: "REPLICATOR", desc: "A built-in group that is used by the File Replication Service (FRS) on domain controllers."},
      "S-1-5-32-554": {constant: "ALIAS_PREW2KCOMPACC", desc: "A backward compatibility group that allows read access on all users and groups in the domain."},
      "S-1-5-32-555": {constant: "REMOTE_DESKTOP", desc: "An alias. Members of this group are granted the right to log on remotely."},
      "S-1-5-32-556": {constant: "NETWORK_CONFIGURATION_OPS", desc: "An alias. Members of this group can have some administrative privileges to manage configuration of networking features."},
      "S-1-5-32-557": {constant: "INCOMING_FOREST_TRUST_BUILDERS", desc: "An alias. Members of this group can create incoming, one-way trusts to this forest."},
      "S-1-5-32-558": {constant: "PERFMON_USERS", desc: "An alias. Members of this group have remote access to monitor this computer."},
      "S-1-5-32-559": {constant: "PERFLOG_USERS", desc: "An alias. Members of this group have remote access to schedule the logging of performance counters on this computer."},
      "S-1-5-32-560": {constant: "WINDOWS_AUTHORIZATION_ACCESS_GROUP", desc: "An alias. Members of this group have access to the computed tokenGroupsGlobalAndUniversal attribute on User objects."},
      "S-1-5-32-561": {constant: "TERMINAL_SERVER_LICENSE_SERVERS", desc: "An alias. A group for Terminal Server License Servers."},
      "S-1-5-32-562": {constant: "DISTRIBUTED_COM_USERS", desc: "An alias. A group for COM to provide computer-wide access controls that govern access to all call, activation, or launch requests on the computer."},
      "S-1-5-32-568": {constant: "IIS_IUSRS", desc: "A built-in group account for IIS users."},
      "S-1-5-32-569": {constant: "CRYPTOGRAPHIC_OPERATORS", desc: "A built-in group account for cryptographic operators."},
      "S-1-5-32-573": {constant: "EVENT_LOG_READERS", desc: "A built-in local group.  Members of this group can read event logs from the local machine."},
      "S-1-5-32-574": {constant: "CERTIFICATE_SERVICE_DCOM_ACCESS", desc: "A built-in local group. Members of this group are allowed to connect to Certification Authorities in the enterprise."},
      "S-1-5-32-575": {constant: "RDS_REMOTE_ACCESS_SERVERS", desc: "Servers in this group enable users of RemoteApp programs and personal virtual desktops access to these resources. This group needs to be populated on servers running RD Connection Broker. RD Gateway servers and RD Web Access servers used in the deployment need to be in this group."},
      "S-1-5-32-576": {constant: "RDS_ENDPOINT_SERVERS", desc: "A group that enables member servers to run virtual machines and host sessions."},
      "S-1-5-32-577": {constant: "RDS_MANAGEMENT_SERVERS", desc: "A group that allows members to access WMI resources over management protocols (such as WS-Management via the Windows Remote Management service)."},
      "S-1-5-32-578": {constant: "HYPER_V_ADMINS", desc: "A group that gives members access to all administrative features of Hyper-V."},
      "S-1-5-32-579": {constant: "ACCESS_CONTROL_ASSISTANCE_OPS", desc: "A local group that allows members to remotely query authorization attributes and permissions for resources on the local computer."},
      "S-1-5-32-580": {constant: "REMOTE_MANAGEMENT_USERS", desc: "Members of this group can access Windows Management Instrumentation (WMI) resources over management protocols (such as WS-Management [DMTF-DSP0226]). This applies only to WMI namespaces that grant access to the user."},
      "S-1-5-33": {constant: "WRITE_RESTRICTED_CODE", desc: "A SID that allows objects to have an ACL that lets any service process with a write-restricted token to write to the object."},
      "S-1-5-64-10": {constant: "NTLM_AUTHENTICATION", desc: "A SID that is used when the NTLM authentication package authenticated the client."},
      "S-1-5-64-14": {constant: "SCHANNEL_AUTHENTICATION", desc: "A SID that is used when the SChannel authentication package authenticated the client."},
      "S-1-5-64-21": {constant: "DIGEST_AUTHENTICATION", desc: "A SID that is used when the Digest authentication package authenticated the client."},
      "S-1-5-65-1": {constant: "THIS_ORGANIZATION_CERTIFICATE", desc: "A SID that indicates that the client's Kerberos service ticket's PAC contained a NTLM_SUPPLEMENTAL_CREDENTIAL structure (as specified in [MS-PAC] section 2.6.4). If the OTHER_ORGANIZATION SID is present, then this SID MUST NOT be present."},
      "S-1-5-80": {constant: "NT_SERVICE", desc: "An NT Service account prefix."},
      "S-1-5-84-0-0-0-0-0": {constant: "USER_MODE_DRIVERS", desc: "Identifies a user-mode driver process."},
      "S-1-5-113": {constant: "LOCAL_ACCOUNT", desc: "A group that includes all users who are local accounts."},
      "S-1-5-114": {constant: "LOCAL_ACCOUNT_AND_MEMBER_OF_ADMINISTRATORS_GROUP", desc: "A group that includes all users who are local accounts and members of the administrators group."},
      "S-1-5-1000": {constant: "OTHER_ORGANIZATION", desc: "A group that includes all users and computers from another organization. If this SID is present, THIS_ORGANIZATION SID MUST NOT be present."},
      "S-1-15-2-1": {constant: "ALL_APP_PACKAGES", desc: "All applications running in an app package context."},
      "S-1-16-0": {constant: "ML_UNTRUSTED", desc: "An untrusted integrity level."},
      "S-1-16-4096": {constant: "ML_LOW", desc: "A low integrity level."},
      "S-1-16-8192": {constant: "ML_MEDIUM", desc: "A medium integrity level."},
      "S-1-16-8448": {constant: "ML_MEDIUM_PLUS", desc: "A medium-plus integrity level."},
      "S-1-16-12288": {constant: "ML_HIGH", desc: "A high integrity level."},
      "S-1-16-16384": {constant: "ML_SYSTEM", desc: "A system integrity level."},
      "S-1-16-20480": {constant: "ML_PROTECTED_PROCESS", desc: "A protected-process integrity level."},
      "S-1-16-28672": {constant: "ML_SECURE_PROCESS", desc: "A secure process integrity level."},
      "S-1-18-1": {constant: "AUTHENTICATION_AUTHORITY_ASSERTED_IDENTITY", desc: "A SID that means the client's identity is asserted by an authentication authority based on proof of possession of client credentials."},
      "S-1-18-2": {constant: "SERVICE_ASSERTED_IDENTITY", desc: "A SID that means the client's identity is asserted by a service."},
      "S-1-18-3": {constant: "FRESH_PUBLIC_KEY_IDENTITY", desc: "A SID that means the client's identity is asserted by an authentication authority based on proof of current possession of client public key credentials."},
      "S-1-18-4": {constant: "KEY_TRUST_IDENTITY", desc: "A SID that means the client's identity is based on proof of possession of public key credentials using the key trust object."},
      "S-1-18-5": {constant: "KEY_PROPERTY_MFA", desc: "A SID that means the key trust object had the multifactor authentication (MFA) property."},
      "S-1-18-6": {constant: "KEY_PROPERTY_ATTESTATION", desc: "A SID that means the key trust object had the attestation property."},
    }
  end
end

if __FILE__ == $PROGRAM_NAME
  unless ARGV.one?
    puts $PROGRAM_NAME + ' <sid>'
    puts ''
    puts 'Data is taken from the following link, also an explenation can be found there:'
    puts 'https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab'
    exit
  end

  if sid = Windows::SID.well_known?(ARGV.first)
    puts 'sid: ' + sid.first
    puts sid.last.map{|k,v| "#{k}: #{v}"}.join("\n")
  else
    puts "no well known entry found"
  end
end
