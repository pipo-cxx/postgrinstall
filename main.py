import ansible_runner
import os.path
import paramiko
import re
import sys

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
local_kp = os.path.join(os.path.expanduser('~'), ".ssh", "ansible_key")
work_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)))
pb_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "playbooks/")

def get_loadlvl(clt):
    client.connect(clt, username='root', key_filename=local_kp)

    stdin, stdout, stderr = client.exec_command("sar -q 1 1 | sed -n '4p' | awk '{ print $5 }'")
    loadlv = float(stdout.read().decode('ascii').strip("\n"))
    print(clt + "'s load level is " + str(loadlv))
    return(loadlv)


def install_sar():
    print("Installing and enabling sar for both hosts...")

    out, err, rc = ansible_runner.run_command(
        host_cwd=work_dir,
        executable_cmd='ansible-playbook',
        cmdline_args=[pb_dir + "sar_inst.yml", '-i', 'inventory'],
        input_fd=sys.stdin,
        output_fd=sys.stdout,
        error_fd=sys.stderr,
    )

    print("rc, {}".format(rc))
    print("out, {}".format(out))
    print("err, {}".format(err))


def install_postgres(other_host):
    print("Installing and configuring PostgreSQL for target host...")

    # This regex was NOT created by me, I found this on the Internet, checked on RegExr for different inputs, verified that it works and used it for this script
    pattern = re.compile("(\\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b)")

    if pattern.match(other_host):
        print("Provided IP address, adding mask...")
        other_host + "/32"

    out, err, rc = ansible_runner.run_command(
        host_cwd=work_dir,
        executable_cmd='ansible-playbook',
        cmdline_args=[pb_dir + "postgres_inst.yml", '-i', 'inventory', '--extra-vars', "script_var=" + work_dir + "/postgres_postinst.sh " + " second_host=" + other_host],
        input_fd=sys.stdin,
        output_fd=sys.stdout,
        error_fd=sys.stderr,
    )

    
    print("rc, {}".format(rc))
    print("out, {}".format(out))
    print("err, {}".format(err))


def main_function(input_hosts):
    print("Attempting to parse provided addresses or names...")
    hosts = input_hosts.split(',')

    if (len(hosts) != 2):
        print("Error parsing provided addresses, expected two separated by comma. Got:\n" + hosts)
        sys.exit(1)

    print("Writing hosts to inventory file...")
    with open("inventory", "w") as inv:
        inv.write(hosts[0] + '\n' + hosts [1] + '\n')
        inv.close()
    
    print("Checking server SSH connectivity...")
    for host in hosts:
        try:
            print("Attempting connection to " + host)
            client.connect(host, username='root', key_filename=local_kp)
            print("Successfully connected to " + host)
            client.close()
        except:
            print("Could not connect to the server as root, resolve the issue and try again")
            sys.exit(1)

    install_sar()
    
    if (get_loadlvl(hosts[0]) <= get_loadlvl(hosts[1])):
        target_host = hosts[0]
        other_host = hosts[1]
    else:
        target_host = hosts[1]
        other_host = hosts[0]

    print(target_host + " chosen as target for installation\n")

    print("Remaking inventory file...")
    with open("inventory", "w") as inv:
        inv.write("[db_servers]\n" + target_host + "\n[other_servers]\n" + other_host)
        inv.close()

    install_postgres(other_host)


if __name__ == ("__main__"):
    num_of_args = len(sys.argv)
    if (num_of_args > 2):
        print("Too many arguments. The command accepts only two IP-addresses or two DNS names separated by a comma")
        sys.exit(1)
    elif (num_of_args < 2):
        print("Insufficient arguments. Please provide IP-addresses or DNS names of two servers separated by a comma")
        sys.exit(1)
    elif (num_of_args == 2):
        main_function(sys.argv[1])
        sys.exit(0)
