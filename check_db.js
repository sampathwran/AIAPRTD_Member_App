const admin = require('firebase-admin');
admin.initializeApp();
admin.firestore().collection('member').get().then(snap => {
  let emailDocs = [];
  snap.docs.forEach(d => {
    if (d.id.includes('@')) {
      emailDocs.push({ id: d.id, email: d.data().user_email || d.data().email, memNo: d.data().membershipNo });
    }
  });
  console.log(JSON.stringify(emailDocs, null, 2));
});
