import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class EditVaccinePage extends StatefulWidget {
  final Map<String, dynamic> report;
  final String userId;
  final String pet_type;

  const EditVaccinePage({
    Key? key,
    required this.report,
    required this.userId,
    required this.pet_type,
  }) : super(key: key);

  @override
  _EditVaccinePageState createState() => _EditVaccinePageState();
}

class _EditVaccinePageState extends State<EditVaccinePage> {
  final ProfileService profileService = ProfileService();
  late TextEditingController vacNameController;
  late TextEditingController weightController;
  late TextEditingController priceController;
  late TextEditingController dateController;
  late TextEditingController locationController;

  List<String> _vacOfDog = [];
  List<String> _vacOfCat = [];
  String? _selectedVac;
  List<String> vaccinationList = [];

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8), // สีพื้นหลังดำ
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  'กำลังบันทึกข้อมูล',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _fetchVacData() async {
    try {
      if (widget.pet_type == 'สุนัข') {
        List<String> breeds = await profileService.fetchVacData('dog_vac');
        setState(() {
          _vacOfDog = breeds;
          vaccinationList = _vacOfDog;
          _selectedVac = _vacOfDog.contains(widget.report['vacName'])
              ? widget.report['vacName']
              : null;
        });
      } else if (widget.pet_type == 'แมว') {
        List<String> breeds = await profileService.fetchVacData('cat_vac');
        setState(() {
          _vacOfCat = breeds;
          vaccinationList = _vacOfCat;
          _selectedVac = _vacOfCat.contains(widget.report['vacName'])
              ? widget.report['vacName']
              : null;
        });
      }
      print('Fetched vaccinations: $vaccinationList');
    } catch (error) {
      print("Failed to fetch vaccine data: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    vacNameController =
        TextEditingController(text: widget.report['vacName'] ?? '');
    weightController =
        TextEditingController(text: widget.report['weight'] ?? '');
    priceController = TextEditingController(text: widget.report['price'] ?? '');
    dateController = TextEditingController(text: widget.report['date'] ?? '');
    locationController =
        TextEditingController(text: widget.report['location'] ?? '');

    _fetchVacData();
  }

  @override
  void dispose() {
    vacNameController.dispose();
    weightController.dispose();
    priceController.dispose();
    dateController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขข้อมูลวัคซีน'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _showLoadingDialog();
              profileService
                  .updateVaccine_MoreToFirestore(
                userId: widget.userId,
                docId: widget.report['id_period'] ?? '',
                petId: widget.report['pet_id'] ?? '',
                vacName: _selectedVac ?? '',
                weight: weightController.text,
                price: priceController.text,
                location: locationController.text,
                date: dateController.text,
              )
                  .then((_) {
                Navigator.of(context).pop(); // ปิด Dialog โหลดข้อมูล
                Navigator.of(context).pop({
                  'id_period': widget.report['id_period'] ?? '',
                  'vacName': _selectedVac ?? '',
                  'weight': weightController.text,
                  'price': priceController.text,
                  'location': locationController.text,
                  'date': dateController.text,
                });
              }).catchError((error) {
                Navigator.of(context)
                    .pop(); // ปิด Dialog โหลดข้อมูลในกรณีเกิดข้อผิดพลาด
                print("Error updating vaccine data: $error");
              });
            },
            icon: const Icon(LineAwesomeIcons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    DropdownButtonFormField<String>(
                      value: _selectedVac,
                      hint: Text('เลือกชื่อวัคซีน'),
                      items: vaccinationList.isNotEmpty
                          ? vaccinationList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child:
                                    Text(value, style: TextStyle(fontSize: 14)),
                              );
                            }).toList()
                          : [
                              DropdownMenuItem<String>(
                                  value: null, child: Text('ไม่มีข้อมูล'))
                            ],
                      onChanged: (newValue) {
                        setState(() {
                          _selectedVac = newValue;
                          vacNameController.text = newValue ?? '';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'ชื่อวัคซีน',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(fontSize: 14),
                            controller: weightController,
                            decoration: InputDecoration(
                              labelText: 'น้ำหนัก',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                            ),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.all(5)),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(fontSize: 14),
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'ราคา',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: dateController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'วันที่',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(
                                  widget.report['date'] ??
                                      DateTime.now().toString()),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );

                            if (pickedDate != null) {
                              dateController.text =
                                  DateFormat('yyyy-MM-dd').format(pickedDate);
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      style: const TextStyle(fontSize: 14),
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'สถานที่',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(LineAwesomeIcons.trash),
                              ),
                              Text('ลบข้อมูล'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}