import 'package:flutter/material.dart';
import 'package:vwc_app/features/signing/interactive_sign_contract_screen.dart';

class SignerDetailsScreen extends StatefulWidget {
  final String docId; // Added docId to pass through to the signing screen
  final String docTitle;
  final String company;
  final List<String> pageUrls;
  final String requiredCode;

  const SignerDetailsScreen({
    super.key,
    required this.docId,
    required this.docTitle,
    required this.company,
    required this.pageUrls,
    required this.requiredCode,
  });

  @override
  State<SignerDetailsScreen> createState() => _SignerDetailsScreenState();
}

class _SignerDetailsScreenState extends State<SignerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _languageController = TextEditingController(text: 'Swahili');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthDateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // Determine normalized language based on what the user types freely
  String get _normalizedLang {
    final val = _languageController.text.trim().toLowerCase();
    if (val.contains('kirundi') || val.contains('rundi') || val.contains('ikirundi')) return 'Kirundi';
    if (val.contains('français') || val.contains('french') || val.contains('fr') || val.contains('faransa')) return 'French';
    if (val.contains('english') || val.contains('eng') || val.contains('ingereza')) return 'English';
    return 'Swahili'; // Default fallback language
  }

  // Multi-language UI Dictionary
  final Map<String, Map<String, String>> _localizedText = {
    'English': {
      'appTitle': 'Signer Details & Verification',
      'subtitle': 'Please type your preferred language, fill out your information, and enter your access code.',
      'languageLabel': 'Preferred Language (Type here) *',
      'nameLabel': 'Full Legal Name *',
      'emailLabel': 'Email Address *',
      'ageLabel': 'Age *',
      'yearLabel': 'Birth Year *',
      'monthDateLabel': 'Month and Date of Birth *',
      'countryLabel': 'Country *',
      'addressLabel': 'Residential Address *',
      'codeLabel': '4-Digit Access Code *',
      'nextButton': 'NEXT: SIGN CONTRACT PAGES',
      'errLang': 'Please type a language',
      'errName': 'Please enter your full name',
      'errEmail': 'Please enter a valid email',
      'errAge': 'Enter age',
      'errYear': 'Enter year',
      'errMonthDate': 'Enter month and date',
      'errCountry': 'Please enter your country',
      'errAddress': 'Please enter your address',
      'errCode': 'Enter 4-digit code',
      'errWrongCode': 'Incorrect Access Code. Please check with your administrator.',
    },
    'Swahili': {
      'appTitle': 'Maelezo ya Msaini na Uhakiki',
      'subtitle': 'Tafadhali andika lugha unayopendelea, jaza taarifa zako, na uweke nambari yako ya siri.',
      'languageLabel': 'Lugha Unayopendelea (Andika hapa) *',
      'nameLabel': 'Jina Kamili la Kisheria *',
      'emailLabel': 'Barua Pepe (Email) *',
      'ageLabel': 'Umri *',
      'yearLabel': 'Mwaka wa Kuzaliwa *',
      'monthDateLabel': 'Mwezi na Tarehe ya Kuzaliwa *',
      'countryLabel': 'Nchi *',
      'addressLabel': 'Anwani ya Makazi *',
      'codeLabel': 'Nambari ya Siri ya Tarakimu 4 *',
      'nextButton': 'INAYOFUATA: SAINI KURASA ZA MKATABA',
      'errLang': 'Tafadhali andika lugha',
      'errName': 'Tafadhali ingiza jina lako kamili',
      'errEmail': 'Tafadhali ingiza barua pepe sahihi',
      'errAge': 'Ingiza umri',
      'errYear': 'Ingiza mwaka',
      'errMonthDate': 'Ingiza mwezi na tarehe',
      'errCountry': 'Tafadhali ingiza nchi yako',
      'errAddress': 'Tafadhali ingiza anwani yako',
      'errCode': 'Ingiza nambari ya tarakimu 4',
      'errWrongCode': 'Nambari ya siri si sahihi. Tafadhali angalia na msimamizi.',
    },
    'Kirundi': {
      'appTitle': 'Amakuru y\'Ugusinya n\'Ubugenzuzi',
      'subtitle': 'Nyamuneka andika ururimi wifuza, wuzuze amakuru yawe, kandi wandike ikode yawe.',
      'languageLabel': 'Ururimi Urondera (Andika hano) *',
      'nameLabel': 'Amazina Yose *',
      'emailLabel': 'Imeli (Email) *',
      'ageLabel': 'Imyaka *',
      'yearLabel': 'Umwaka Wavutsemwo *',
      'monthDateLabel': 'Ukwezi n\'Itariki y\'Ivuka *',
      'countryLabel': 'Igihugu *',
      'addressLabel': 'Aho Uba *',
      'codeLabel': 'Ikode y\'Imibare 4 *',
      'nextButton': 'BIKURIKIRA: GUSINYA URUPAPURA RW\'AMasezerano',
      'errLang': 'Nyamuneka andika ururimi',
      'errName': 'Nyamuneka wandike amazina yawe yose',
      'errEmail': 'Nyamuneka wandike imeli yemewe',
      'errAge': 'Andika imyaka',
      'errYear': 'Andika umwaka',
      'errMonthDate': 'Andika ukwezi n\'itariki',
      'errCountry': 'Nyamuneka andika igihugu cawe',
      'errAddress': 'Nyamuneka andika aho uba',
      'errCode': 'Andika ikode y\'imibare 4',
      'errWrongCode': 'Ikode siyo. Nyamuneka yunguruza n\'umuyobozi.',
    },
    'French': {
      'appTitle': 'Détails du Signataire & Vérification',
      'subtitle': 'Veuillez saisir votre langue préférée, remplir vos informations et entrer votre code d\'accès.',
      'languageLabel': 'Langue Préférée (Tapez ici) *',
      'nameLabel': 'Nom Légal Complet *',
      'emailLabel': 'Adresse Email *',
      'ageLabel': 'Âge *',
      'yearLabel': 'Année de Naissance *',
      'monthDateLabel': 'Mois et Date de Naissance *',
      'countryLabel': 'Pays *',
      'addressLabel': 'Adresse Résidentielle *',
      'codeLabel': 'Code d\'Accès à 4 Chiffres *',
      'nextButton': 'SUIVANT : SIGNER LE CONTRAT',
      'errLang': 'Veuillez saisir une langue',
      'errName': 'Veuillez entrer votre nom complet',
      'errEmail': 'Veuillez entrer un email valide',
      'errAge': 'Entrez l\'âge',
      'errYear': 'Entrez l\'année',
      'errMonthDate': 'Entrez le mois et la date',
      'errCountry': 'Veuillez entrer votre pays',
      'errAddress': 'Veuillez entrer votre adresse',
      'errCode': 'Entrez le code à 4 chiffres',
      'errWrongCode': 'Code d\'accès incorrect. Veuillez vérifier auprès de l\'administrateur.',
    },
  };

  String t(String key) {
    final lang = _normalizedLang;
    return _localizedText[lang]?[key] ?? _localizedText['English']![key]!;
  }

  @override
  void dispose() {
    _languageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _yearController.dispose();
    _monthDateController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _proceedToDocument() {
    if (!_formKey.currentState!.validate()) return;

    if (_codeController.text.trim() != widget.requiredCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('errWrongCode')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Proceed to contract signing pages, passing docId and language preference
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => InteractiveSignContractScreen(
          docId: widget.docId, // Pass the required docId here!
          docTitle: widget.docTitle,
          company: widget.company,
          pageUrls: widget.pageUrls,
          signerName: _nameController.text.trim(),
          signerEmail: _emailController.text.trim(),
          signerAge: _ageController.text.trim(),
          signerYear: _yearController.text.trim(),
          signerMonthDate: _monthDateController.text.trim(),
          signerCountry: _countryController.text.trim(),
          signerAddress: _addressController.text.trim(),
          selectedLanguage: _normalizedLang,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(t('appTitle')),
        backgroundColor: const Color(0xFF8B1E24),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.edit_note, size: 64, color: Color(0xFF8B1E24)),
                const SizedBox(height: 12),

                // Language free-text box
                TextFormField(
                  controller: _languageController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: t('languageLabel'),
                    hintText: 'e.g. Swahili, Kirundi, French, English',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.translate, color: Color(0xFF8B1E24)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? t('errLang') : null,
                ),
                const SizedBox(height: 20),

                Text(
                  widget.docTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.company,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  t('subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // Full Legal Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: t('nameLabel'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF8B1E24)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? t('errName') : null,
                ),
                const SizedBox(height: 14),

                // Email Address
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: t('emailLabel'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF8B1E24)),
                  ),
                  validator: (val) => val == null || !val.contains('@') ? t('errEmail') : null,
                ),
                const SizedBox(height: 14),

                // Age and Birth Year
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t('ageLabel'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.cake, color: Color(0xFF8B1E24)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? t('errAge') : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t('yearLabel'),
                          hintText: 'YYYY',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.length != 4 ? t('errYear') : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Month and Date
                TextFormField(
                  controller: _monthDateController,
                  decoration: InputDecoration(
                    labelText: t('monthDateLabel'),
                    hintText: 'e.g. October 15',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF8B1E24)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? t('errMonthDate') : null,
                ),
                const SizedBox(height: 14),

                // Country
                TextFormField(
                  controller: _countryController,
                  decoration: InputDecoration(
                    labelText: t('countryLabel'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.public, color: Color(0xFF8B1E24)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? t('errCountry') : null,
                ),
                const SizedBox(height: 14),

                // Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: t('addressLabel'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.home, color: Color(0xFF8B1E24)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? t('errAddress') : null,
                ),
                const SizedBox(height: 14),

                // Access Code
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 6),
                  decoration: InputDecoration(
                    labelText: t('codeLabel'),
                    hintText: '****',
                    border: const OutlineInputBorder(),
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF8B1E24)),
                  ),
                  validator: (val) => val == null || val.length != 4 ? t('errCode') : null,
                ),
                const SizedBox(height: 24),

                // Next Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E24),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _proceedToDocument,
                    child: Text(
                      t('nextButton'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}