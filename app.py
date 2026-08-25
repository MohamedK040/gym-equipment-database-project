import mysql.connector
from mysql.connector import Error


def create_connection():
    try:
        connection = mysql.connector.connect(
            host="localhost",
            user="root",
            password="YOUR_PASSWORD",
            database="gym_maintenance"
        )
        if connection.is_connected():
            print("Connected to MySQL database.")
        return connection
    except Error as e:
        print(f"Error while connecting to MySQL: {e}")
        return None


def show_equipment(connection):
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM equipment")
        rows = cursor.fetchall()
        print("\n--- Equipment ---")
        for row in rows:
            print(row)
    except Error as e:
        print(f"Error: {e}")


def show_fault_reports(connection):
    try:
        cursor = connection.cursor()
        query = """
            SELECT
                fault_report.report_id,
                equipment.name AS equipment_name,
                fault_report.description,
                fault_report.severity,
                fault_report.report_date
            FROM fault_report
            JOIN equipment
                ON fault_report.equipment_id = equipment.equipment_id
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        print("\n--- Fault Reports ---")
        for row in rows:
            print(row)
    except Error as e:
        print(f"Error: {e}")


def show_service_tickets(connection):
    try:
        cursor = connection.cursor()
        query = """
            SELECT
                service_ticket.ticket_id,
                technician.first_name,
                technician.last_name,
                service_ticket.status,
                service_ticket.priority
            FROM service_ticket
            JOIN technician
                ON service_ticket.technician_id = technician.technician_id
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        print("\n--- Service Tickets ---")
        for row in rows:
            print(row)
    except Error as e:
        print(f"Error: {e}")


def show_ticket_actions(connection):
    try:
        cursor = connection.cursor()
        query = """
            SELECT
                service_ticket.ticket_id,
                service_action.action_type,
                service_action.action_description,
                service_action.action_date
            FROM service_ticket
            JOIN service_action
                ON service_ticket.ticket_id = service_action.ticket_id
            ORDER BY service_ticket.ticket_id, service_action.action_date
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        print("\n--- Maintenance Actions per Ticket ---")
        for row in rows:
            print(row)
    except Error as e:
        print(f"Error: {e}")


def show_fault_statistics(connection):
    try:
        cursor = connection.cursor()
        query = """
            SELECT
                equipment.name,
                COUNT(fault_report.report_id) AS total_faults
            FROM equipment
            JOIN fault_report
                ON equipment.equipment_id = fault_report.equipment_id
            GROUP BY equipment.equipment_id, equipment.name
            ORDER BY total_faults DESC
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        print("\n--- Fault Statistics (most reported faults) ---")
        for row in rows:
            print(row)
    except Error as e:
        print(f"Error: {e}")


def show_technician_workload(connection):
    try:
        cursor = connection.cursor()
        query = """
            SELECT
                technician.first_name,
                technician.last_name,
                COUNT(service_ticket.ticket_id) AS total_tickets
            FROM technician
            LEFT JOIN service_ticket
                ON technician.technician_id = service_ticket.technician_id
            GROUP BY technician.technician_id,
                     technician.first_name, technician.last_name
            ORDER BY total_tickets DESC
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        print("\n--- Technician Workload ---")
        for row in rows:
            print(row)
    except Error as e:
        print(f"Error: {e}")


def create_service_ticket(connection):
    try:
        report_id = int(input("Enter fault report ID: "))
        technician_id = int(input("Enter technician ID: "))
        priority = input("Enter priority (Low / Medium / High): ")

        cursor = connection.cursor()
        cursor.callproc("create_service_ticket", [report_id, technician_id, priority])
        connection.commit()
        print("Service ticket created successfully.")
    except ValueError:
        print("Invalid input. Please enter numeric IDs.")
    except Error as e:
        if e.errno == 1062:
            print("This fault report already has a service ticket. "
                  "Only one ticket is allowed per fault report.")
        else:
            print(f"Error: {e}")


def close_service_ticket(connection):
    try:
        ticket_id = int(input("Enter ticket ID to close: "))
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE service_ticket SET status = 'Closed' WHERE ticket_id = %s",
            (ticket_id,)
        )
        connection.commit()
        if cursor.rowcount == 0:
            print("No ticket found with that ID.")
        else:
            print("Ticket closed. Equipment status was updated automatically "
                  "by the database trigger.")
    except ValueError:
        print("Invalid input. Please enter a numeric ID.")
    except Error as e:
        print(f"Error: {e}")


def main():
    connection = create_connection()
    if connection is None:
        print("Could not connect to database.")
        return

    while True:
        print("\n===== Gym Equipment Maintenance System =====")
        print("1. Show all equipment")
        print("2. Show all fault reports")
        print("3. Show all service tickets")
        print("4. Show maintenance actions per ticket")
        print("5. Show fault statistics (most reported faults)")
        print("6. Show technician workload")
        print("7. Create a new service ticket")
        print("8. Close a service ticket")
        print("9. Exit")

        choice = input("Choose an option: ")

        if choice == "1":
            show_equipment(connection)
        elif choice == "2":
            show_fault_reports(connection)
        elif choice == "3":
            show_service_tickets(connection)
        elif choice == "4":
            show_ticket_actions(connection)
        elif choice == "5":
            show_fault_statistics(connection)
        elif choice == "6":
            show_technician_workload(connection)
        elif choice == "7":
            create_service_ticket(connection)
        elif choice == "8":
            close_service_ticket(connection)
        elif choice == "9":
            print("Exiting program.")
            break
        else:
            print("Invalid choice. Please try again.")

    connection.close()
    print("Database connection closed.")


if __name__ == "__main__":
    main()
