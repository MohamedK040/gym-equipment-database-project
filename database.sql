DROP TABLE IF EXISTS service_action;
DROP TABLE IF EXISTS service_ticket;
DROP TABLE IF EXISTS fault_report;
DROP TABLE IF EXISTS equipment_status;
DROP TABLE IF EXISTS technician;
DROP TABLE IF EXISTS equipment;

CREATE TABLE equipment (
    equipment_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    model VARCHAR(100),
    purchase_date DATE,
    location VARCHAR(100) NOT NULL
);

CREATE TABLE equipment_status (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    equipment_id INT NOT NULL,
    status VARCHAR(50) NOT NULL,
    changed_at DATETIME NOT NULL,
    note VARCHAR(255),
    FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id)
);

CREATE TABLE fault_report (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    equipment_id INT NOT NULL,
    report_date DATE NOT NULL,
    description VARCHAR(255) NOT NULL,
    severity VARCHAR(50) NOT NULL,
    reported_by VARCHAR(100) NOT NULL,
    FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id)
);

CREATE TABLE technician (
    technician_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(100) NOT NULL,
    specialization VARCHAR(100)
);

CREATE TABLE service_ticket (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    report_id INT NOT NULL UNIQUE,
    technician_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    status VARCHAR(50) NOT NULL,
    priority VARCHAR(50) NOT NULL,
    FOREIGN KEY (report_id) REFERENCES fault_report(report_id),
    FOREIGN KEY (technician_id) REFERENCES technician(technician_id)
);

CREATE TABLE service_action (
    action_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    action_date DATE NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    action_description VARCHAR(255) NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES service_ticket(ticket_id)
);

INSERT INTO equipment (name, category, brand, model, purchase_date, location) VALUES
('Treadmill A1', 'Cardio', 'Technogym', 'Run Excite 700', '2022-03-15', 'Cardio Zone'),
('Exercise Bike B2', 'Cardio', 'Life Fitness', 'IC7', '2021-06-10', 'Cardio Zone'),
('Bench Press C3', 'Strength', 'Hammer Strength', 'Olympic Bench', '2020-09-01', 'Strength Area'),
('Rowing Machine D4', 'Cardio', 'Concept2', 'Model D', '2023-01-20', 'Main Hall'),
('Leg Press E5', 'Strength', 'Matrix', 'MG-PL70', '2021-11-05', 'Strength Area');

INSERT INTO equipment_status (equipment_id, status, changed_at, note) VALUES
(1, 'Operational', '2026-03-01 08:00:00', 'Initial status'),
(2, 'Needs Service', '2026-03-02 09:30:00', 'Resistance issue'),
(3, 'Operational', '2026-03-01 10:15:00', 'Initial status'),
(4, 'Out of Order', '2026-03-03 14:00:00', 'Display not working'),
(5, 'Operational', '2026-03-01 11:00:00', 'Initial status');

INSERT INTO fault_report (equipment_id, report_date, description, severity, reported_by) VALUES
(2, '2026-03-02', 'Bike resistance does not change properly', 'Medium', 'Anna'),
(4, '2026-03-03', 'Screen is black and machine does not start', 'High', 'Johan'),
(2, '2026-03-04', 'Pedal makes unusual noise', 'Low', 'Emma'),
(1, '2026-03-05', 'Running belt slips during use', 'High', 'Lukas');

INSERT INTO technician (first_name, last_name, phone, email, specialization) VALUES
('Erik', 'Svensson', '0701234567', 'erik.svensson@gymtech.com', 'Cardio Equipment'),
('Maria', 'Nilsson', '0702345678', 'maria.nilsson@gymtech.com', 'Electrical Repairs'),
('David', 'Andersson', '0703456789', 'david.andersson@gymtech.com', 'Strength Equipment');

INSERT INTO service_ticket (report_id, technician_id, created_at, status, priority) VALUES
(1, 1, '2026-03-02 12:00:00', 'In Progress', 'Medium'),
(2, 2, '2026-03-03 15:00:00', 'Open', 'High'),
(4, 1, '2026-03-05 16:30:00', 'Open', 'High');

INSERT INTO service_action (ticket_id, action_date, action_type, action_description) VALUES
(1, '2026-03-02', 'Inspection', 'Checked the resistance mechanism and internal settings'),
(1, '2026-03-03', 'Adjustment', 'Adjusted resistance control and recalibrated the bike'),
(2, '2026-03-04', 'Inspection', 'Inspected power supply and display connections'),
(3, '2026-03-06', 'Inspection', 'Examined treadmill belt and roller alignment');

SELECT * FROM equipment;
SELECT * FROM equipment_status;
SELECT * FROM fault_report;
SELECT * FROM technician;
SELECT * FROM service_ticket;
SELECT * FROM service_action;

SELECT 
    fault_report.report_id,
    equipment.name AS equipment_name,
    fault_report.description,
    fault_report.severity,
    fault_report.report_date
FROM fault_report
JOIN equipment 
ON fault_report.equipment_id = equipment.equipment_id;

SELECT 
    service_ticket.ticket_id,
    technician.first_name,
    technician.last_name,
    service_ticket.status,
    service_ticket.priority
FROM service_ticket
JOIN technician 
ON service_ticket.technician_id = technician.technician_id;

SELECT 
    service_ticket.ticket_id,
    service_action.action_type,
    service_action.action_description,
    service_action.action_date
FROM service_ticket
JOIN service_action
ON service_ticket.ticket_id = service_action.ticket_id;

SELECT 
    equipment.name,
    COUNT(fault_report.report_id) AS total_faults
FROM equipment
JOIN fault_report
ON equipment.equipment_id = fault_report.equipment_id
GROUP BY equipment.equipment_id, equipment.name
ORDER BY total_faults DESC;

SELECT 
    technician.first_name,
    technician.last_name,
    COUNT(service_ticket.ticket_id) AS total_tickets
FROM technician
JOIN service_ticket
ON technician.technician_id = service_ticket.technician_id
GROUP BY technician.technician_id, technician.first_name, technician.last_name;



DROP TRIGGER IF EXISTS after_service_ticket_closed;

DELIMITER $$

CREATE TRIGGER after_service_ticket_closed
AFTER UPDATE ON service_ticket
FOR EACH ROW
BEGIN
    IF NEW.status = 'Closed' AND OLD.status <> 'Closed' THEN
        INSERT INTO equipment_status (equipment_id, status, changed_at, note)
        SELECT 
            fault_report.equipment_id,
            'Operational',
            NOW(),
            'Automatically updated after service ticket was closed'
        FROM fault_report
        WHERE fault_report.report_id = NEW.report_id;
    END IF;
END$$

DELIMITER ;

UPDATE service_ticket
SET status = 'Closed'
WHERE ticket_id = 2;

SELECT * FROM equipment_status;



DROP PROCEDURE IF EXISTS create_service_ticket;

DELIMITER $$

CREATE PROCEDURE create_service_ticket(
    IN p_report_id INT,
    IN p_technician_id INT,
    IN p_priority VARCHAR(50)
)
BEGIN
    INSERT INTO service_ticket (report_id, technician_id, created_at, status, priority)
    VALUES (p_report_id, p_technician_id, NOW(), 'Open', p_priority);
END$$

DELIMITER ;

CALL create_service_ticket(3, 3, 'Low');

SELECT * FROM service_ticket;