# List of printers to add
$printers = @(
    @{
        Name       = "The name of it"
        IPAddress  = "192.168.1.Theprinter"
        DriverName = "The exact name of the driver - must already be installed"
    },
    @{
        Name       = "Another Printer"
        IPAddress  = "192.168.1.I think you know"
        DriverName = "The exact name of the driver - must already be installed"
    }
)

foreach ($printer in $printers) {
    $portName = "IP_" + $printer.IPAddress

    # Add port if it doesn't exist
    if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
        Add-PrinterPort -Name $portName -PrinterHostAddress $printer.IPAddress
        Write-Host "Created port $portName"
    }

    # Add printer
    if (-not (Get-Printer -Name $printer.Name -ErrorAction SilentlyContinue)) {
        Add-Printer -Name $printer.Name -PortName $portName -DriverName $printer.DriverName
        Write-Host "Added printer: $($printer.Name)"
    } else {
        Write-Host "Printer already exists: $($printer.Name)"
    }
}
