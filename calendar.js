const { google } = require('googleapis');
const { getAuthenticatedClient } = require('./auth');

async function createEvent({ title, startTime, endTime, colorId }) {
  const auth = getAuthenticatedClient();
  const calendar = google.calendar({ version: 'v3', auth });

  const event = {
    summary: title || 'Work Session',
    start: { dateTime: startTime.toISOString() },
    end: { dateTime: endTime.toISOString() },
    colorId: String(colorId || '7'),
  };

  const response = await calendar.events.insert({
    calendarId: 'primary',
    resource: event,
  });

  return response.data;
}

module.exports = { createEvent };
