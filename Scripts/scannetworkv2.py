import nmap

# Initialize the nmap scanner
nm = nmap.PortScanner()

# Get the IP address of the local machine
nm.scan(hosts='127.0.0.1', arguments='-sn')
ip_address = nm.all_hosts()[0]

# Scan the network the local machine is connected to
nm.scan(hosts=f'{ip_address}/24', arguments='-F')

# Write the results to a text file
with open('scan_results.txt', 'w') as f:
    for host in nm.all_hosts():
        f.write(f'Host : {host} ({nm[host].hostname()})\n')
        f.write(f'State : {nm[host].state()}\n')
        for proto in nm[host].all_protocols():
            f.write(f'Protocol : {proto}\n')

            # Write the open ports for each protocol
            lport = nm[host][proto].keys()
            lport = sorted(lport)
            for port in lport:
                f.write(f'port : {port}\tstate : {nm[host][proto][port]["state"]}\n')
        f.write('\n')
